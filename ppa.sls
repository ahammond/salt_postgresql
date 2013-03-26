{% set pg_pref = '/etc/apt/preferences.d/pgdg.pref' %}

deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main:
  pkgrepo.managed:
    - dist: precise
    - file: /etc/apt/sources.list.d/postgresql.list
    - keyid: ACCC4CF8
    - keyserver: keys.gnupg.net

{{ pg_pref }}:
  file.managed:
    - source: salt://postgresql/files{{ pg_pref }}
    - require:
      - pkgrepo: deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main

update_apt:
  cmd.wait:
    - name: apt-get update
    - watch:
      - file: /etc/apt/sources.list.d/*
