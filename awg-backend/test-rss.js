const Parser = require('rss-parser');
const parser = new Parser();
parser.parseURL('https://www.pinterest.com/pinterest/official-news.rss').then(feed => console.log(JSON.stringify(feed.items[0], null, 2)));
