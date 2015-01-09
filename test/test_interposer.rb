# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestInterposer < TuneMyGcTestCase
  def setup
    TuneMyGc.interposer.uninstall
  end

  def test_init
    interposer = TuneMyGc.interposer
    assert !interposer.installed
    assert_equal [], interposer.subscriptions
  end

  def test_install_uninstall
    interposer = TuneMyGc.interposer
    interposer.install
    TuneMyGc.interposer.on_initialized

    assert_equal 2, interposer.subscriptions.size
    assert interposer.installed
    assert_nil interposer.install

    interposer.uninstall
    assert_equal [], interposer.subscriptions
  end

  def test_gc_hooks
    interposer = TuneMyGc.interposer
    interposer.install
    TuneMyGc.interposer.on_initialized

    GC.start(full_mark: true, immediate_sweep: false)

    assert TuneMyGc.snapshotter.buffer.any?{|s| s[1] == :GC_CYCLE_START }

    interposer.uninstall
    assert_equal [], interposer.subscriptions
  end

  def test_requests_limit
    interposer = TuneMyGc.interposer
    interposer.install
    TuneMyGc.interposer.on_initialized

    assert_equal 2, interposer.subscriptions.size

    ENV["RUBY_GC_TUNE_REQUESTS"] = "2"

    process_request
    assert_equal 2, interposer.subscriptions.size
    process_request
    assert_equal 0, interposer.subscriptions.size
    interposer.uninstall
  ensure
    ENV.delete("RUBY_GC_TUNE_REQUESTS")
  end
end