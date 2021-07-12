#!/usr/bin/env bash
# Demonstration script for shellnium to take full-page screenshots of websites
# E.g. ./demo3.sh https://google.com/

# Check bash version is >= 4.0. Some functionality won't work otherwise.
case "${BASH_VERSION}" in ''|[123].*) printf 'Bash 4.0+ required\n' >&2; exit 1; ;; esac

# Function that generates javascript
# The javascript will attempt to load all images of the page by scrolling to the bottom
# and return the height for the screenshot
scroll_page(){
	cat <<-EOF
		let waitload = new Promise(function(res) {
			function loadimages() {
				setTimeout(function() {
					if(typeof images[i] != 'undefined'){
						images[i].scrollIntoView();
					}
					if(i++ < images.length) {
						loadimages(images);
					} else {
						res();
					}
				}, 50)
			}
			let i = 0, images = document.getElementsByTagName('img');
			loadimages(images);
		});
		let body = document.body, html = document.documentElement;
		let height = Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight);
		waitload.then(function(){
			g = document.createElement('div');
			g.setAttribute('id', 'screengrabber-pageisloaded');
			document.body.appendChild(g);
		});
		return height;
	EOF
}

# Tests if the page is loaded by checking for a <div> that the scroll_page function injected
page_loaded(){
	[[ $(exec_script "if(document.getElementById('screengrabber-pageisloaded')) return true;" | jq -r '.value') == true ]]
}

# Sets the path to shellnium
declare -r -- SHELLNIUM_PATH="${HOME}/git/shellnium/"

# Tests dependencies are met
declare -ar -- DEPENDS=('chromedriver' 'chromium' 'setsid' 'killall' 'ps')
hash -- "${DEPENDS[@]}" || exit 1

# Kills the chromedriver and chromium processes upon exit
trap -- 'killall chromedriver chromium; exit' ERR 0 1 2 3 6 13 14 15

# Starts chromedriver in the background if it's not already running
# Adds the SHELLNIUM_PATH to the directory stack so that you can source shellnium without cd'ing
# And then sources the shellnium script
{
	ps -C chromedriver || setsid -f chromedriver
	pushd "${SHELLNIUM_PATH}"
	. lib/selenium.sh --headless
	popd
} &>/dev/null || {
	echo 'Unable to start chromedriver or source shellnium. Please ensure path to shellnium is correct'
	exit
}

# For each argument to the script it will take screenshots of the entire page
for url; do
	echo "Screenshotting ${url}"
	navigate_to "${url}"
	page_height=$(exec_script "$(scroll_page)" | jq -r '.value')
	until page_loaded; do sleep 1; done
	set_window_rect 0 0 1920 "${page_height}" >/dev/null
	screenshot "screenshot_$((i++)).png"
done
