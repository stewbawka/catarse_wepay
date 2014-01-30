App.addChild('WePayForm', _.extend({
  el: '#catarse_wepay_form',

  events: {
    'click input[type=submit]': 'onSubmitToWePay',
    'keyup #user_document' : 'onUserDocumentKeyup'
  },

  activate: function() {
    this.loader = $('.loader');
    this.parent.contributionId = $('input#contribution_id').val();
    this.parent.projectId = $('input#project_id').val();
  },

  onSubmitToWePay: function(e) {
    $(e.currentTarget).hide();
    this.loader.show();
  }
}, window.WePay.UserDocument));
