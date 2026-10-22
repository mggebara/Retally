"""Reproducers other than the reference pipeline.

* ``filesystem`` — ``FilesystemReproducer`` (``--reproducer claude-code``):
  scores the files a Claude Code session wrote under
  ``benchmark/reproductions/<entry>/<mode>/<run_id>/``.
* ``render_task`` — prepares one (entry, mode, run_id) cell for such a
  session: the task file, the paper text and the mode's data mount.
* ``check_attempt`` — the session's claim-feedback (independent / seeded)
  and missing-name (blind) check.

See "Claude Code as a reproducer" in ``benchmark/README.md``.
"""
