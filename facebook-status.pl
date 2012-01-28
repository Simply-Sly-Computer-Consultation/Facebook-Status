#!/usr/bin/perl -w
 
#===============================================================================
#
# Facebook status script v2.2
#
# This script allows you to update your Facebook status from the shell.
#
# Copyright (C) 2011 Matt West <matt at mattdanger dot net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# For a copy of the GNU General Public License visit <http://www.gnu.org/licenses/>.
#
#===============================================================================
 
# Be sure you have installed the LWP and Crypt::SSLeay packages from CPAN
use LWP;
use HTTP::Cookies;
use Term::ReadKey;
use strict;
 
# General vars
my $login;
my $password;
my $status;
my $auth_key;
my $fb_dtsg;
my $response;
my $user_agent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.6) Gecko/20060728 Firefox/1.5.0.6";
my @header = ( 'Referer' => 'http://www.facebook.com/', 
               'User-Agent' => $user_agent);
my $cookie_jar = HTTP::Cookies->new(
                file => 'cookies.dat',
                autosave => 1,
                ignore_discard => 1);
my $browser = LWP::UserAgent->new;
$browser->cookie_jar($cookie_jar);
 
# Get login information & the status message to send.
print "Facebook login name: ";
$login = <>; chomp($login);
 
print "Password: ";
ReadMode('noecho');
$password = ReadLine(0); chomp($password); ReadMode 0;
 
print "\nYour status (Facebook appears to have a 232 character limit): ";
$status = <>; chomp($status);
print "\nSending... ";
 
#================================================
# Login and get auth key
#================================================

$response = $browser->post('https://www.facebook.com/login.php?m=m&amp;refsrc=http%3A%2F%2Fm.facebook.com%2Fhome.php&amp;refid=8', 
                           ['email' => $login,
                            'pass' => $password,
                            'login' => 'Log In'], @header);
$cookie_jar->extract_cookies( $response );
$cookie_jar->save;
$response = $browser->get('http://m.facebook.com/home.php', @header);

$auth_key = $response->content;
$auth_key =~ s/\n//g;
$auth_key =~ s/^.*name="post_form_id" value="//;
$auth_key =~ s/".*$//;

$fb_dtsg = $response->content;
$fb_dtsg =~ s/\n//g;
$fb_dtsg =~ s/^.*name="fb_dtsg" value="//;
$fb_dtsg =~ s/".*$//;

#================================================
# Submit the status update
#================================================
 
@header = ('Referer' => 'http://m.facebook.com/a/home.php', 
           'User-Agent' => $user_agent, 
           'Host' => 'm.facebook.com');
 
$response = $browser->post('http://m.facebook.com/a/home.php?re974fcaf&refid=7&rbb94a931', 
                           ['fb_dtsg' => $fb_dtsg,
                            'post_form_id' => $auth_key,
                            'status' => $status,
                            'update' => 'Share'], @header);
 
# Did we do good here?
if ($response->content eq '') {
  print "Done!\n\n";
} else {
  print "An error occurred while setting your profile status.\n\n";
  $response->content;
}
 
# Now that we're done we can delete the cookies.dat file.
exec('rm cookies.dat');
