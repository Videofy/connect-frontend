
module.exports =
  bQuery.view()
    .set("tagName", "div")
    .defaults('agreement')
    .set("className", "agreement-row")
    .boundText('status','.status')
    .make()

