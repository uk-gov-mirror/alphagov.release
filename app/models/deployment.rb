class Deployment < ApplicationRecord
  after_create :record_to_statsd
  belongs_to :application

  validates :version, :environment, :application_id, presence: true

  scope :newest_first, -> { order("created_at DESC") }

  def self.last_deploy_to(environment)
    where(environment: environment)
      .order("created_at DESC")
      .first
  end

  def previous_deployment
    @previous_deployment ||= Deployment
      .where(application_id: application_id, environment: environment)
      .where("id < ?", id)
      .order("id DESC")
      .first
  end

  def previous_version
    previous_deployment.try(:version)
  end

  def commits
    @commits ||=
      begin
        Services.github.compare(application.repo, previous_version, version).commits.reverse.map do |commit|
          Commit.new(commit.to_h, application)
        end
      rescue Octokit::NotFound
        []
      end
  end

  def diff_url
    application.repo_compare_url(previous_version, version)
  end

private

  # Record the deployment to statsd and thence to graphite
  def record_to_statsd
    # Only record production deployments in production graphite
    if environment == "production" || environment == "production-aws"
      key = "deploys.#{application.shortname}"
      GovukStatsd.increment(key)
    end
  end
end
