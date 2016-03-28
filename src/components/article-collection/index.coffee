mkCrudCollection = require('crud-collection')

ArticleCollection = mkCrudCollection
  baseUri: 'article'
  model: require('article-model')

module.exports = ArticleCollection
