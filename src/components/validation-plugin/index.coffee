module.exports = (config={})-> (v)->
  { attribute } = config
  attribute = attribute or 'validation'

  v.init (opts={})->
    checkErrors = (errors)=>
      els = Array::slice.call(@el.querySelectorAll("[#{attribute}]"))
      for el in els
        el.classList.remove('required')

      for err in errors
        continue unless field = err.field
        el = @el.querySelector("[#{attribute}=#{field}]")
        el?.classList.add('required')

    @model.on 'geterrors', checkErrors.bind(@)