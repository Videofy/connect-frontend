
class AgreementModel extends Backbone.Model
  idAttribute: "_id"

AgreementModel.STATUS =
  PENDING_SIGNATURE: "Pending Signature",
  SIGNED: "signed"

AgreementModel.COMMISSION_TYPE =
  GROSS: "gross"

module.exports = AgreementModel
