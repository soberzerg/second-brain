# Inbox Processor

Quick scan and categorization of items in `000_Inbox/`.

> Для полной обработки с интеграцией в wiki используй `/ingest`.

## Task

1. **Scan** — list all files in `000_Inbox/` (exclude README.md)
2. **Categorize** each item:

   | Destination | Критерий |
   | ----------- | -------- |
   | `200_Projects/` | Есть дедлайн, конкретный результат |
   | `300_Blog/` | Идеи контента, черновики |
   | `400_Planning/` | Планы, заметки |
   | `500_Research/` | Справочный материал, знания |
   | Delete | Неактуально, дубликат |

3. **Output** — таблица:

   ```text
   File: [filename]
   Type: [detected type]
   Destination: [suggested folder]
   Action: [/ingest | move | delete]
   ```

4. **Flag** stale items (older than 7 days)

## Next Steps

- Для каждого файла, который стоит интегрировать в wiki: запустить `/ingest <filename>`
- `/ingest` автоматически обновит `index.md` и `log.md`
