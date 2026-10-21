# Native packet fixture

`native-wire.hex` contains synthetic test data emitted by the production
QuestSync adapter in `pjw345/tortoise-wow`, revision
`591c68d49312c91fde933d38a0613db414471148`. It contains no live player data.

Regenerate it with `QuestSyncTest path/to/native-wire.hex` from the server
repository's standalone `tests/playerbot-quest-sync` build. Pass that new file
to `python tests/test_client.py --wire path/to/native-wire.hex` to validate
current server output. The checked-in fixture keeps the client suite runnable
without a server checkout; it does not prove compatibility with future changes.
