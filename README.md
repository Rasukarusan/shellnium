# shellnium

![demo](https://user-images.githubusercontent.com/17779386/85990922-aacbd080-ba2d-11ea-8e88-cc9b79075b31.gif)

## Bash Webdriver

```sh
#!/usr/bin/env bash
source ./selenium.sh

main() {
    # Move to Google
    navigate_to 'https://google.co.jp'

    # Get the search box
    local searchBox=$(find_element 'name' 'q')

    # send keys
    send_keys $searchBox "animal\n"
}

main
```

## Demo

```sh
$ sh demo.sh

# or
$ sh demo2.sh
```

`demo2.sh` is required iTerm2 and MacOS.

This script is headless and display chromedriver's behavior as iTerm's background.  
The above GIF is `demo2.sh`.

## Todo

The bash webdriver `selenium.sh` is incomplete.  
Here's what `selenium.sh` can currently do

- delete session
- open url
- find element
- send keys
- click element
- take screenshot
- exec javascript

## Article

https://qiita.com/Rasukarusan/items/70a54bd38c71a07ff7bd
