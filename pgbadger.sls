{% from 'postgresql/map.jinja' import postgresql with context %}
# Install pgbadger to run in incremental mode

include:
  - {{ postgresql.repository }}

pgbadger:
  pkg.installed:
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}

{{ postgresql.pgbadger_outdir }}:
  file.directory:
    - user: postgres
    - group: postgres
    - mode: 755

{% set pgbadger_cron = "/usr/bin/pgbadger --quiet --incremental --jobs 8 --outdir %s --last-parsed %s/pgbadger_incremental_file.data `/bin/find %s -name '*.log' 2> /dev/null`" % (postgresql.pgbadger_outdir, postgresql.log_dir, postgresql.log_dir) %}
{{ pgbadger_cron }}:
  cron.present:
    - user: postgres
    - minute: random
    - hour: '*'
    - require:
      - pkg: pgbadger
