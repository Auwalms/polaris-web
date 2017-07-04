module.exports = {
	"Welcome page" : function(browser) {
		browser.url("http://localhost:5050");
		browser.expect.element("#initial-setup-page").to.be.present.before(1000);
		browser.expect.element("initial-setup-welcome").to.be.present.before(1000);
		browser.expect.element("initial-setup-welcome h2").text.to.contain("Welcome to Polaris");
		browser.click("button.submit");
	},

	"Mount point setup" : function(browser) {
		browser.expect.element("initial-setup-mount").to.be.present.before(1000);
		browser.expect.element("initial-setup-mount h2").text.to.contain("Music Sources");
		browser.expect.element('button.submit').to.not.be.enabled;
		browser.setValue('input#source', 'test/collection');
		browser.setValue('input#name', 'test_music');
		browser.expect.element('button.submit').to.be.enabled;
		browser.click("button.submit");
	}
};