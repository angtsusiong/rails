# frozen_string_literal: true

require "abstract_unit"
require "mailers/base_mailer"
require "active_support/log_subscriber/test_helper"
require "active_support/testing/stream"
require "action_mailer/log_subscriber"

class AMLogSubscriberTest < ActionMailer::TestCase
  include ActiveSupport::LogSubscriber::TestHelper, ActiveSupport::Testing::Stream

  def setup
    super
    ActionMailer::LogSubscriber.attach_to :action_mailer
  end

  class TestMailer < ActionMailer::Base
    def receive(mail)
      # Do nothing
    end
  end

  def set_logger(logger)
    ActionMailer::Base.logger = logger
  end

  def test_deliver_is_notified
    BaseMailer.welcome.deliver_now
    wait

    assert_equal(1, @logger.logged(:info).size)
    assert_match(/Sent mail to system@test\.lindsaar\.net/, @logger.logged(:info).first)

    assert_equal(2, @logger.logged(:debug).size)
    assert_match(/BaseMailer#welcome: processed outbound mail in [\d.]+ms/, @logger.logged(:debug).first)
    assert_match(/Welcome/, @logger.logged(:debug).second)
  ensure
    BaseMailer.deliveries.clear
  end

  def test_deliver_message_when_perform_deliveries_is_false
    BaseMailer.welcome_without_deliveries.deliver_now
    wait

    assert_equal(1, @logger.logged(:info).size)
    assert_match("Skipped sending mail to system@test.lindsaar.net as `perform_deliveries` is false", @logger.logged(:info).first)

    assert_equal(2, @logger.logged(:debug).size)
    assert_match(/BaseMailer#welcome_without_deliveries: processed outbound mail in [\d.]+ms/, @logger.logged(:debug).first)
    assert_match("Welcome", @logger.logged(:debug).second)
  ensure
    BaseMailer.deliveries.clear
  end

  def test_receive_is_notified
    fixture = File.read(File.expand_path("fixtures/raw_email", __dir__))
    silence_stream(STDERR) { TestMailer.receive(fixture) }
    wait
    assert_equal(1, @logger.logged(:info).size)
    assert_match(/Received mail/, @logger.logged(:info).first)
    assert_equal(1, @logger.logged(:debug).size)
    assert_match(/Jamis/, @logger.logged(:debug).first)
  end
end
