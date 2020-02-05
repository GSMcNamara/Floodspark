function retry(isDone, next) {
  var current_trial = 0,
    max_retry = 50,
    interval = 10,
    is_timeout = false;
  var id = window.setInterval(
    function() {
      if (isDone()) {
        window.clearInterval(id);
        next(is_timeout);
      }
      if (current_trial++ > max_retry) {
        window.clearInterval(id);
        is_timeout = true;
        next(is_timeout);
      }
    },
    10
  );
}

async function privateCheck(callback) {
	//Chrome
	if (location.protocol === 'https:') {
    		if ('storage' in navigator && 'estimate' in navigator.storage) {
			const {usage, quota} = await navigator.storage.estimate();
			json["storage"]=quota;
		}
	}
	//Firefox
	var is_private;
	if (window.indexedDB && /Firefox/.test(window.navigator.userAgent)) {
		var db;
		try {
			db = window.indexedDB.open('test');
		} catch (e) {
			is_private = true;
		}

		if (typeof is_private === 'undefined') {
			retry(
				function isDone() {
					return db.readyState === 'done' ? true : false;
				},
				function next(is_timeout) {
					if (!is_timeout) {
						is_private = db.result ? false : true;
					}
				}
			);
		}
	}

	retry(
		function isDone() {
			return typeof is_private !== 'undefined' ? true : false;
		},
		function next(is_timeout) {
			if (is_private == true) {
				json["browser.firefox.private"]=true;
			}
			callback();
		}
	);
}

function post () {
	var xhr = new XMLHttpRequest();
	xhr.open("POST", '/fs', true);
	xhr.setRequestHeader('Content-Type', 'application/json');
	xhr.send(JSON.stringify(json));
}

function main () {
	json = {"screen.height":screen.height,"window.innerHeight":window.innerHeight,"navigator.webdriver":navigator.webdriver};
	privateCheck(post);
}

json = {};
main();
