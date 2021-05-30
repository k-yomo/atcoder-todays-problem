# AtCoder Today's Problem
executing `post_todays_problem.rb` posts the randomly picked today's AtCoder problem to Slack channel.

## Prerequisite
- Ruby 2.6.5
- [Create Incoming WebHook](https://atcoder-battle.slack.com/apps/new/A0F7XDUAZ-incoming-webhooks)
- Create Spreadsheet and [Configure SheetDB API](https://sheetdb.io/)
    - Spreadsheet and SheetDB are used to exclude already solved problems by listed users. 
    - The spreadsheet must have `user_id` row as following.
  ```
  user_id
  tourist
  ac_user1
  ac_user2
  ```

## Example 
```sh
SLACK_WEBHOOK_URL=<URL> \
SHEET_DB_API_ID=<ID> \
ruby post_todays_problem.rb
```

