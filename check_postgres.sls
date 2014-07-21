{% from 'postgresql/map.jinja' import postgresql with context %}

include:
  - {{ postgresql.repository }}

check_postgres_pkg:
  pkg.installed:
    - name: check_postgres
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}

{% set make_symlinks = "/usr/bin/check_postgres.pl --action=rebuild_symlinks" %}
{{ make_symlinks }}:
  cmd.run:
    - cwd: /usr/local/bin
    - unless: test -x /usr/local/bin/check_postgres_archive_ready
    - require:
      - pkg: check_postgres_pkg
