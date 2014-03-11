{% from 'postgresql/map.jinja' import postgresql with context %}
{% from 'nginx/map.jinja' import nginx with context %}
# Install pgbadger to run in incremental mode

include:
  - {{ postgresql.repository }}
  - nginx

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

{% set nginx_default = "/etc/nginx/conf.d/default.conf" %}
{{ nginx_default }}:
  file.absent:
    - require:
      - pkg: nginx

{% set nginx_conf = "/etc/nginx/conf.d/pgbadger.conf" %}
{{ nginx_conf }}:
  file.managed:
    - source: salt://postgresql/files{{ nginx_conf }}
    - template: jinja
    - user: nginx
    - group: nginx
    - pgbadger_outdir: {{ postgresql.pgbadger_outdir }}
    - require:
      - file: {{ postgresql.pgbadger_outdir }}
      - file: {{ nginx_default }}
