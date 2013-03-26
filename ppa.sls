{% set pg_pref = '/etc/apt/preferences.d/pgdg.pref' %}

deb http://ppa.launchpad.net/pitti/postgresql/ubuntu precise main:
  pkgrepo.managed:
    - dist: precise
    - file: /etc/apt/sources.list.d/postgresql.list
    - keyid: FB322597BBC86D52FEE950E299B656EA8683D8A2
    - keyserver: keyserver.ubuntu.com

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
