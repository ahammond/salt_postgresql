{% for user, arguments in pillar['postgresql']['users'].iteritems() %}
{{ user }}:
  postgres_user.present:
    - runas: postgres
    {% for k, v in arguments.iteritems() %}
    - {{ k }}: {{ v }}
    {% endfor %}
{% endfor %}
