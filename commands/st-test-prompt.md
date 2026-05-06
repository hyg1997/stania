Test AI advisor endpoint with a sample message and validate response format.

## Steps

1. Read auth credentials — either from env or prompt user for email/password.

2. Login to get JWT:
```bash
curl -s -X POST <apiUrl>/auth/login -H "Content-Type: application/json" -d '{"email":"<email>","password":"<password>"}'
```
Read `apiUrl` from `.stania/config.json` → `deploy.serviceUrl`, or fallback to `https://shenia-api-1025165990776.us-central1.run.app`.

3. Send test message to advisor:
```bash
curl -s -X POST <apiUrl>/api/advisor/messages -H "Content-Type: application/json" -H "Authorization: Bearer <token>" -d '{"message":"<testMessage>"}'
```
Default test messages by type:
- `--routine`: "Créame una rutina de piernas para el miércoles"
- `--meal`: "Registra mi almuerzo: pollo con arroz y ensalada"
- `--activity`: "Jugué voley 90 minutos hoy"
- Custom: use the argument text as message

4. Validate response:
```
=== PROMPT TEST ===
Message: "<sent message>"
Response: <first 100 chars of content>...
Actions: <count> found
  - [type] "<label>" — payload keys: [list]

CHECKS:
[x] Response has content (non-empty)
[x] Actions block parsed correctly
[x] Action type is valid (create_routine|update_nutrition_plan|log_meal|log_activity)
[x] Action has label
[x] Date in payload matches today (<today>)
[ ] FAIL: Date is "<wrong date>" — expected "<today>"
```

5. If `--apply` flag: also call apply-action endpoint and verify entity was created.

## Rules

- Never store credentials in files
- Timeout 30s for AI response
- If no actions in response, report as WARNING not FAIL (AI may not always suggest actions)
