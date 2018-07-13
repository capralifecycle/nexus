#!/usr/bin/env groovy

// See https://github.com/capralifecycle/jenkins-pipeline-library
@Library('cals') _

def dockerImageName = '923402097046.dkr.ecr.eu-central-1.amazonaws.com/buildtools/service/nexus'

def jobProperties = []

if (env.BRANCH_NAME == 'master') {
  jobProperties << pipelineTriggers([
    // Build a new version every night so we keep up to date with upstream changes
    cron('H H(2-6) * * *'),
  ])
}

buildConfig([
  jobProperties: jobProperties,
  slack: [
    channel: '#cals-dev-info',
    teamDomain: 'cals-capra',
  ],
]) {
  dockerNode {
    stage('Checkout source') {
      checkout scm
    }

    def img
    def lastImageId = dockerPullCacheImage(dockerImageName)

    stage('Build Docker image') {
      def args = ""
      if (params.docker_skip_cache) {
        args = " --no-cache"
      }
      img = docker.build(dockerImageName, "--cache-from $lastImageId$args --pull .")
    }

    def isSameImage = dockerPushCacheImage(img, lastImageId)

    stage('Test build') {
      docker.image('docker').inside {
        sh "./test.sh ${img.id}"
      }
    }

    if (env.BRANCH_NAME == 'master' && !isSameImage) {
      stage('Push Docker image') {
        def tagName = sh([
          returnStdout: true,
          script: 'date +%Y%m%d-%H%M'
        ]).trim() + '-' + env.BUILD_NUMBER

        img.push(tagName)
        img.push('latest')

        slackNotify message: "New Docker image available: $dockerImageName:$tagName"
      }
    }
  }
}
