require 'feature_helper'
require 'api_test_helper'
require 'cookie_names'

# HUB-71 Delete with test teardown
RSpec.describe 'When the user visits the about identity accounts page' do
  before(:each) do
    set_session_and_ab_session_cookies!('no_questions_v2' => 'no_questions_v2_variant')
    stub_transactions_list
    stub_api_idp_list_for_loa(default_idps)
  end

  it 'includes the appropriate feedback source' do
    visit '/about-identity-accounts'

    expect_feedback_source_to_be(page, 'ABOUT_IDENTITY_ACCOUNTS_PAGE', '/about-identity-accounts')
  end

  it 'displays content in Welsh' do
    visit '/am-gyfrifon-hunaniaeth'

    expect(page).to have_content t('cookie_message.link', locale: :cy)
  end

  it 'will show "Where you can use your identity account" section listing public transactions' do
    visit '/about-identity-accounts'

    expect(page).to have_content t('hub.about_identity_accounts.summary')
    expect(page).to have_content t('hub.about_identity_accounts.details')
    expect(page).to have_content 'register for an identity profile'
    expect(page).to have_content 'Register for an identity profile (forceauthn & no cycle3)'
  end

  it 'will go to choosing a certified company page when start now is clicked if user on LOA2 journey' do
    visit '/about-identity-accounts'
    click_link('Start now')

    expect(page).to have_current_path('/choose-a-certified-company')
  end
end