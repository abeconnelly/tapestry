class DrbController < ApplicationController
  skip_before_filter :login_required
  skip_before_filter :ensure_enrolled
  before_filter :valid_callback
  include PhrccrsHelper

  def userlog
    @user = User.find_by_id(params[:user_id])
    @user.log(params[:message],nil,request.remote_ip,params[:user_message]) if not @user.nil?
  end

  def ccr_downloaded
    user_id = params[:user_id]
    updated = params[:updated]
    ccr_filename = params[:ccr_filename]

    # We don't want duplicates
    Ccr.find_by_user_id_and_version(user_id,updated).destroy unless Ccr.find_by_user_id_and_version(user_id,updated).nil?

    db_ccr = parse_xml_to_ccr_object(ccr_filename)
    db_ccr.user_id = user_id
    db_ccr.save
  end

  def report_ready
    user_id = params[:user_id]
    report_id = params[:report_id]
    filename = params[:filename]

    @r = Report.find(report_id)
    @r.status = 'Ready'
    @r.created = Time.now()
    @r.path = filename
    @r.save!
  end

  def report_failed
    user_id = params[:user_id]
    report_id = params[:report_id]
    error_message = params[:error]

    @r = Report.find(report_id)
    @r.status = 'Failed: ' + error_message
    @r.save!
  end

  def process_file_ready
    # STUB, TODO FIXME
  end

  def process_file_failed
    # STUB, TODO FIXME
  end

  protected

  def valid_callback
    if request.remote_ip != DRB_CALLBACK_SOURCE_IP then
      # Uh-oh, something is wrong. E-mail sysadmins...
      SystemMailer.deliver_error_notification("Callback from invalid IP: #{request.remote_ip}","Only callbacks from DRB_CALLBACK_SOURCE_IP (#{DRB_CALLBACK_SOURCE_IP}) are allowed.")
      return false
    else
      return true
    end
  end

end
