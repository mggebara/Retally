# Retally reproduction task: ${entry_id} (${mode}, run ${run_id})

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `${entry_id}`, mode `${mode}`, run `${run_id}`
- Paper: ${title}
- Paper text (extracted from the PDF; tables may be garbled): `${paper_path}`
- Data (the ONLY data you get): `${mount_path}`
- Output directory (the ONLY place you write): `${output_dir}`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `${mount_path}` as data, and `${paper_path}` as
  the paper.
- Do not read anything else in this repository or on this machine: not the
  catalog YAMLs under `benchmark/papers/`, not `.cache/datasets/`, not
  `benchmark/results/`, not other reproductions under `benchmark/reproductions/`,
  not other task directories.  If you nevertheless read any other file, list
  it in `files_read_outside_mount` in `reproduction.json`, with why.
[[if seeded]]
- Seeded mode: the authors' own analysis scripts are on disk under the data
  directory and reproduced below under "Original Replication Scripts".  You
  may follow them:

${seeded_intro}
[[end]]
[[if seeded,independent]]
- You may compare your `RESULT:` values with the claimed values yourself.
  Every time you do that and then change the script, record the run you
  compared as an attempt with `kind: "claim"`, and write the comparison you
  made to that attempt's `feedback.txt`, one line per off-target claim in
  the form `<name>: reproduced <v>, claimed <c>`.  Produce it with:

      cd ${main_checkout} && uv run python -m benchmark.reproducers.check_attempt --run-dir ${output_dir} --stdout <that attempt's stdout.txt>

  At most ${max_claim_refinements} `kind: "claim"` attempts.
- At most ${max_refinements} `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).
[[end]]
[[if independent]]

${independent_block}
[[end]]
[[if blind]]

${independent_block}
- Never search the paper text for the quantities' reported values, and never
  adjust the specification toward any number in the paper.  Use the paper
  for its method, sample and variable definitions only.
- `kind: "claim"` attempts are forbidden: you are not told the claimed
  values and must not compare against them.
- At most ${max_refinements} `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).
- To check that every quantity got a value (this prints names only, never a
  value or a target):

      cd ${main_checkout} && uv run python -m benchmark.reproducers.check_attempt --run-dir ${output_dir} --stdout <a stdout.txt>
[[end]]

${claims_block}
${dataset_block}
${output_convention_block}
${code_requirements_block}
[[if seeded]]
${package_scripts_block}
[[end]]
## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=${output_dir}/script.R   # or ${output_dir}/attempt-<n>/script.R
    ${run_command} > "$$(dirname "$$SCRIPT")/stdout.txt" 2> "$$(dirname "$$SCRIPT")/stderr.txt"; echo "exit code: $$?"

The sandbox time limit is ${timeout} seconds (memory ${memory}, ${cpus} CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' ${timeout}` (or `gtimeout ${timeout}` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=${label} | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `${output_dir}` already holds `render.json`; leave it
there.  Add:

```
${output_dir}/
  script.R  stdout.txt  stderr.txt      # the FINAL run: its RESULT: lines are what is scored
  attempt-1/  attempt-2/  ...           # every execution BEFORE the final one, in order
    script.R  stdout.txt  stderr.txt  feedback.txt   # feedback.txt when kind is not ""
  reproduction.json                     # written LAST
```

- `attempt-<n>` directories are every execution before the final one, in
  the order they ran; the final files at the top are the run whose
  `RESULT:` lines are scored.  If you go back to an earlier attempt, copy
  that attempt's files to the top level as the final run.
- `feedback.txt` holds what you acted on before the next attempt: the error
  you fixed (`kind: "error"`) or the `check_attempt` comparison
  (`kind: "claim"`).
- Write `reproduction.json` last, in this schema:

```
${schema}
```

End your final message with the final run's `RESULT:` lines and a short
note.  Nothing needed for scoring may live only in the message: the files
are the record.

Do not edit any file in the repository; your only writes are under `${output_dir}`.
