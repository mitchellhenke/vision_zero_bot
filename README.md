# vision_zero_bot
A Twitter bot to automatically send out Vision-Zero-related tweets for Milwaukee, using R and GitHub actions.

The instructions [here](https://www.rostrum.blog/2020/09/21/londonmapbot/) were very helpful in figuring this out.

## Current status
The bot is in production status, tweeting a summary tweet once a week on Wednesdays.

## Data
The bot uses data from [Community Maps](https://transportal.cee.wisc.edu/partners/community-maps/crash/search/BasicSearch.do) to gather information about traffic crashes in Milwaukee.

> Community Maps provides a statewide map of all police reported motor vehicle crashes in Wisconsin from 2010 to the current year. Fatal crashes are included from 2001. Crashes occurring on or after January 1, 2017 are mapped using geo-coded locations from the Wisconsin DT4000 police crash report. Prior year crashes have been geo-coded from the crash report location descriptions. Crashes that have not been geo-coded are not displayed on the map. Community Maps is maintained by the Wisconsin Traffic Operations and Safety (TOPS) Laboratory for research purposes and as a service to the Wisconsin Department of Transportation Bureau of Transportation Safety. See Community Maps for more information: https://CommunityMaps.wi.gov/.

## Basic functionality
Once a week, triggered by a cron job via Github actions, injury and fatality data is pulled from Community Maps. The bot posts a summary of the injuries and fatalities in the preceding week, as well as a running total of the calendar year and tweets that out. The tweet also includes an image with the same data.

## Potential future features
- [ ] tweet other Vision Zero related messages?
- [ ] automatically retweet tweets located in Madison and tagged #VisionZero?
If you have suggestions for a feature, create an issue in the repository!


