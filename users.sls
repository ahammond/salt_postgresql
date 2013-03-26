{% for user, args in pillar['postgresql']['users'].items() %}
{{ user }}:
  postgres_user.present:
    runas: postgres
    {% for k, v in args.items() %}
    {{ k }}: {{ v }}
    {% endfor %}
{% endfor %}
