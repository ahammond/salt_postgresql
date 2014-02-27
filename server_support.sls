{% from 'postgresql/map.jinja' import postgresql with context %}

git:
  pkg.installed

{% set check_postgres_src_dir = "/usr/src/check_postgres" %}
{{ check_postgres_src_dir }}:
  file.directory:
    - user: postgres
    - group: postgres

{% set check_postgres_repo = "https://github.com/bucardo/check_postgres.git" %}
{{ check_postgres_repo }}:
  git.latest:
    - rev: "2.21.0"
    - target: {{ check_postgres_src_dir }}
    - user: postgres
    - requires:
      - file: {{ check_postgres_src_dir }}

check_postgres_requirements:
  pkg.installed:
    - pkgs:
      - perl-ExtUtils-MakeMaker
      - perl-DBD-Pg
      - perl-DBI

{% set perl_makefile = "perl Makefile.PL" %}
{{ perl_makefile }}:
  cmd.run:
    - cwd: {{ check_postgres_src_dir }}
    - user: postgres
    - unless: test -e {{ check_postgres_src_dir }}/Makefile
    - require:
      - git: {{ check_postgres_repo }}
      - pkg: check_postgres_requirements

make:
  cmd.run:
    - cwd: {{ check_postgres_src_dir }}
    - user: postgres
    - unless: test -d {{ check_postgres_src_dir }}/blib
    - require:
      - cmd: {{ perl_makefile }}

{% set check_postgres_bin = "/usr/local/bin/check_postgres.pl" %}
make install:
  cmd.run:
    - cwd: {{ check_postgres_src_dir }}
    - unless: test -x {{ check_postgres_bin }}
    - require:
      - cmd: make

{% set make_symlinks = "/usr/local/bin/check_postgres.pl --action=rebuild_symlinks" %}
{{ make_symlinks }}:
  cmd.run:
    - cwd: /usr/local/bin
    - unless: test -x /usr/local/bin/check_postgres_archive_ready
    - require:
      - cmd: make install
