"""Tests for the AST-based hyperparameter auditor."""

from __future__ import annotations

from retally.models import AuditStatus, HyperparameterSpec
from retally.validation.hyperparam_audit import audit_hyperparameters


def _spec(name: str, value):
    return HyperparameterSpec(name=name, value=value)


# ── Match ────────────────────────────────────────────────────────────────


def test_match_simple_int():
    code = (
        "from sklearn.ensemble import RandomForestClassifier\nclf = RandomForestClassifier(n_estimators=100)"
    )
    [audit] = audit_hyperparameters(code, [_spec("n_estimators", 100)])
    assert audit.status is AuditStatus.MATCH
    assert audit.observed_value == 100


def test_match_float_with_tolerance():
    # The paper might say 0.1; JSON round-trips can introduce tiny noise.
    code = "f(test_size=0.1)"
    [audit] = audit_hyperparameters(code, [_spec("test_size", 0.10000000000001)])
    assert audit.status is AuditStatus.MATCH


def test_match_string_value():
    code = "SVC(kernel='rbf', gamma='scale')"
    audits = audit_hyperparameters(code, [_spec("kernel", "rbf"), _spec("gamma", "scale")])
    assert [a.status for a in audits] == [AuditStatus.MATCH, AuditStatus.MATCH]


def test_match_tuple_vs_list_interchangeable():
    # Paper text might extract to a list; sklearn idiom uses a tuple.
    code = "MLPClassifier(hidden_layer_sizes=(32,))"
    [audit] = audit_hyperparameters(code, [_spec("hidden_layer_sizes", [32])])
    assert audit.status is AuditStatus.MATCH


def test_match_when_kwarg_appears_in_multiple_calls():
    # random_state passed to both train_test_split and the model;
    # one match is sufficient.
    code = "train_test_split(X, y, random_state=42)\nLogisticRegression(random_state=42)"
    [audit] = audit_hyperparameters(code, [_spec("random_state", 42)])
    assert audit.status is AuditStatus.MATCH


def test_match_picks_earliest_when_multiple_matches():
    code = "f(C=1.0)\ng(C=1.0)"
    [audit] = audit_hyperparameters(code, [_spec("C", 1.0)])
    assert audit.status is AuditStatus.MATCH


# ── Mismatch ─────────────────────────────────────────────────────────────


def test_mismatch_reports_observed_value():
    code = "LogisticRegression(C=0.5)"
    [audit] = audit_hyperparameters(code, [_spec("C", 1.0)])
    assert audit.status is AuditStatus.MISMATCH
    assert audit.observed_value == 0.5
    assert "C=1.0" in audit.notes
    assert "C=0.5" in audit.notes


def test_mismatch_string():
    code = "SVC(kernel='linear')"
    [audit] = audit_hyperparameters(code, [_spec("kernel", "rbf")])
    assert audit.status is AuditStatus.MISMATCH
    assert audit.observed_value == "linear"


def test_mismatch_tuple_different_length():
    code = "MLPClassifier(hidden_layer_sizes=(32, 16))"
    [audit] = audit_hyperparameters(code, [_spec("hidden_layer_sizes", [32])])
    assert audit.status is AuditStatus.MISMATCH


def test_mismatch_when_one_call_matches_a_different_value():
    # Both observations are mismatches; pick the first.
    code = "f(C=2.0)\ng(C=3.0)"
    [audit] = audit_hyperparameters(code, [_spec("C", 1.0)])
    assert audit.status is AuditStatus.MISMATCH
    assert audit.observed_value == 2.0


# ── Not found ────────────────────────────────────────────────────────────


def test_not_found_when_kwarg_absent():
    code = "LogisticRegression()"
    [audit] = audit_hyperparameters(code, [_spec("C", 1.0)])
    assert audit.status is AuditStatus.NOT_FOUND
    assert "C" in audit.notes


def test_not_found_distinct_from_misnamed_kwarg():
    # A spec named 'regularization' will not match a 'C' kwarg.
    code = "LogisticRegression(C=1.0)"
    [audit] = audit_hyperparameters(code, [_spec("regularization", 1.0)])
    assert audit.status is AuditStatus.NOT_FOUND


# ── Unresolved ───────────────────────────────────────────────────────────


def test_unresolved_when_value_is_variable():
    code = "c = 1.0\nLogisticRegression(C=c)"
    [audit] = audit_hyperparameters(code, [_spec("C", 1.0)])
    assert audit.status is AuditStatus.UNRESOLVED
    assert audit.observed_value == "c"


def test_unresolved_when_value_is_function_call():
    code = "LogisticRegression(C=compute_c())"
    [audit] = audit_hyperparameters(code, [_spec("C", 1.0)])
    assert audit.status is AuditStatus.UNRESOLVED


def test_unresolved_with_some_literal_some_variable_picks_literal_path():
    # If ANY observation is literal-and-matches, status is MATCH.
    code = "f(C=c)\ng(C=1.0)"
    [audit] = audit_hyperparameters(code, [_spec("C", 1.0)])
    assert audit.status is AuditStatus.MATCH


def test_mismatch_beats_unresolved_when_literal_present():
    # If we have one literal observation that doesn't match plus one
    # unresolved, prefer MISMATCH — we have proof of a wrong value.
    code = "f(C=c)\ng(C=2.0)"
    [audit] = audit_hyperparameters(code, [_spec("C", 1.0)])
    assert audit.status is AuditStatus.MISMATCH
    assert audit.observed_value == 2.0


# ── Edge cases ───────────────────────────────────────────────────────────


def test_empty_spec_list_returns_empty():
    assert audit_hyperparameters("any code", []) == []


def test_syntax_error_returns_unresolved_for_every_spec():
    audits = audit_hyperparameters(
        "def foo(:  # genuinely broken Python",
        [_spec("C", 1.0), _spec("n_estimators", 100)],
    )
    assert [a.status for a in audits] == [AuditStatus.UNRESOLVED, AuditStatus.UNRESOLVED]
    for a in audits:
        assert "parse" in a.notes.lower()


def test_kwargs_unpacking_is_ignored():
    # **params should not crash the walker and should not satisfy a
    # spec — we can't see what's inside.
    code = "params = {'C': 1.0}\nLogisticRegression(**params)"
    [audit] = audit_hyperparameters(code, [_spec("C", 1.0)])
    assert audit.status is AuditStatus.NOT_FOUND


def test_bool_does_not_match_int_one():
    # Python: True == 1 is True, but the auditor should not say a
    # paper-stated value of 1 was matched by a `fit_intercept=True`.
    code = "LogisticRegression(fit_intercept=True)"
    [audit] = audit_hyperparameters(code, [_spec("fit_intercept", 1)])
    assert audit.status is AuditStatus.MISMATCH


def test_none_value():
    code = "RandomForestClassifier(max_depth=None)"
    [audit] = audit_hyperparameters(code, [_spec("max_depth", None)])
    assert audit.status is AuditStatus.MATCH


def test_audit_preserves_spec_order():
    code = "LogisticRegression(C=1.0, random_state=42)"
    specs = [_spec("random_state", 42), _spec("C", 1.0), _spec("max_iter", 100)]
    audits = audit_hyperparameters(code, specs)
    assert [a.spec.name for a in audits] == ["random_state", "C", "max_iter"]
