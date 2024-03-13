c.content.autoplay = False
c.session.lazy_restore = True
config.bind('J', 'scroll-page 0 0.5')
config.bind('K', 'scroll-page 0 -0.5')
config.bind('h', 'tab-prev')
config.bind('l', 'tab-next')
config.bind('t', 'set-cmd-text -s :open -t')

#config.set('content.notifications.enabled', True, '*.slack.com')

config.load_autoconfig(False)

c.url.searchengines = {
  'DEFAULT': 'https://duckduckgo.com/?ia=web&q={}',
  '!a': 'https://www.amazon.com/s?k={}',
  '!d': 'https://thefreedictionary.com/{}',
  '!e': 'https://www.ebay.com/sch/i.html?_nkw={}',
  '!g': 'https://google.com/search?hl=en&q={}',
  '!i': 'https://www.instagram.com/explore/tags/{}',
  '!m': 'https://www.google.com/maps/search/{}',
  '!p': 'https://pry.sh/{}',
  '!r': 'https://old.reddit.com/search?q={}',
  '!s': 'https://slickdeals.net/newsearch.php?q={}&searcharea=deals&searchin=first',
  '!t': 'https://twitter.com/search?q={}',
  '!th': 'https://www.thesaurus.com/browse/{}',
  '!w': 'https://en.wikipedia.org/wiki/{}',
  '!y': 'https://youtube.com/results?search_query={}'
}
