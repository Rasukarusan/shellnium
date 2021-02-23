## Find Element

You can use `find_element` method to find a element.
```sh
find_element ${property} ${value}
```

The `${property}` is following:
- 'id'
- 'name'
- 'css selector'
- 'link text'
- 'partial link text'
- 'tag name'
- 'class name'
- 'xpath'

To find multiple elements, you can use `find_elements` method.
```sh
find_elements ${property} ${value}
```

### Find Element By Id

Example usage:
```html
<html>
<body>
  <p id="welcome">Hi, there!</p>
</body>
<html>
```

Command usage:
```sh
element=$(find_element 'id' 'welcome')
```

### Find Element By Name

Example usage:
```html
<html>
<body>
  <input name="username" type="text" />
</body>
<html>
```

Command usage:
```sh
element=$(find_element 'name' 'username')
```

### Find Element By Css Selector

Example usage:
```html
<html>
<body>
  <p class="content">Site content goes here.</p>
</body>
<html>
```

Command usage:
```sh
element=$(find_element 'css selector' 'p.content')
```

### Find Element By Link Text

Example usage:
```html
<html>
<body>
  <a href="login.html">Login</a>
</body>
<html>
```

Command usage:
```sh
element=$(find_element 'link text' 'Login')
```

### Find Element By Partial Link Text

Example usage:
```html
<html>
<body>
  <a href="login.html">Login</a>
</body>
<html>
```

Command usage:
```sh
element=$(find_element 'partial link text' 'Log')
```

### Find Element By Tag Name

Example usage:
```html
<html>
<body>
  <h1>Welcome</h1>
</body>
<html>
```

Command usage:
```sh
element=$(find_element 'tag name' 'h1')
```

### Find Element By Class Name

Example usage:
```html
<html>
<body>
  <h1 class="title">Welcome</h1>
</body>
<html>
```

Command usage:
```sh
element=$(find_element 'class name' 'title')
```

### Find Element By Xpath

Example usage:
```html
<html>
<body>
  <div id="contents">
    <p>welcome</p>
    <p>here</p>
  </div>
</body>
<html>
```

Command usage:
```sh
element=$(find_element 'xpath' '//*[@id="contents"]/p[1]')
```

## Find Elements

Example usage:
```html
<html>
<body>
  <p>welcome</p>
  <p>here</p>
</body>
<html>
```

Command usage:
```sh
elements=($(find_elements 'tag name' 'p'))
get_text ${elements[0]} # welcome
get_text ${elements[1]} # here
```

## Find Element From Element

Example usage:
```html
<html>
<body>
  <div id="content">
    <p>welcome</p>
  </div>
  <div id="comment">
    <p>here</p>
  </div>
</body>
<html>
```

Command usage:
```sh
content=$(find_element 'id' 'content')
element=$(find_element_from_element $content 'tag name' 'p')
get_text $element # welcome
```

## File Upload

Example usage:
```html
<html>
<body>
  <input id="input-file" type="file"  />
</body>
</html>
```

Command usage:
```sh
# Use xpath
input=$(find_element 'xpath' "//input[@type='file' and @id='input-file']")
# absolute path
send_keys $input "/Users/yourname/Downloads/graph.png"
```


## Multiple File Upload

Example usage:
```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width" />
    <title>Test</title>
  </head>
<body>
  <input id="input-files" type="file" onchange="OnFileSelect(this)" multiple />
  <ul id="description"></ul>
  <script>
    function OnFileSelect(inputElement) {
        let fileList = inputElement.files
        let fileCount = fileList.length
        let fileListBody = `Number of files: ${fileCount}<br/><br/>`
        for ( let i = 0; i < fileCount; i++ ) {
            let file = fileList[i]
            fileListBody += `[${i+1}]<br/>`
            fileListBody += `name             = ${file.name}<br/>`
            fileListBody += `type             = ${file.type}<br/>`
            fileListBody += `size             = ${file.size}<br/>`
            fileListBody += `lastModified     = ${file.lastModified}<br/>`
            fileListBody += '<br/>'
        }
        document.getElementById('description').innerHTML = fileListBody
    }
  </script>
</body>
</html>
```

Command usage:
```sh
local input=$(find_element 'xpath' "//input[@type='file' and @id='input-files']")
# Selenium supports muti-upload directly by calling sendKeys on the <input> element with the paths separated by a line-break character.
send_keys $input "/Users/yourname/Downloads/graph.png\n/Users/yourname/Downloads/develop.jpg"
```

## Other methods

Please see [core.sh](https://github.com/Rasukarusan/shellnium/blob/master/lib/core.sh).
