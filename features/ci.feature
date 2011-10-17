Feature: CI 

  Background:
    Given the temp directory is clean
    Given I am in the temp directory
  
  Scenario: Install CI on Amazon AWS using new Rails template
    When I create a new Rails project using a Rails template
    And I vendor Lobot
    And I put Lobot in the Gemfile
    And I add a gem with an https://github.com source
    And I run bundle install
    And I run the Lobot generator
    And I enter my info into the ci.yml file
    And I change my ruby version
    And I push to git
    And I run the server setup
    And I bootstrap
    And I deploy
    Then CI is green

  Scenario: Installing Lobot on a rails3 project
    When I create a new Rails project using a Rails template
    And I vendor Lobot
    And I put Lobot in the Gemfile
    And I run bundle install
    And I run the Lobot generator
    Then rake reports ci tasks as being available