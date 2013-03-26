{% for user, arguments in pillar['postgresql']['users'].iteritems() %}
postgres_user_{{ user }}:
  postgres_user.present:
    - name: {{ user }}
    - runas: postgres
    {% for k, v in arguments.iteritems() %}
    - {{ k }}: {{ v }}
    {% endfor %}
{% endfor %}
