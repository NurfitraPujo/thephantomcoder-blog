---
layout: post
title:  "Why i used Bridgetown to build my blog"
date:   2023-05-28 17:45:57 +0700
categories: updates
tags: ['blogging','cms']
description: |
  Bridgetown is new contender in Jamstack platform. 
  It was supposed to the successor of the already old Jekyll. 
  The idea is bringing convenient platform like Jekyll but with more modern and robust environment.
  It combines the best experience of ruby, javascript and markdown together to create convenient blogging platform
---
## About Bridgetown

Bridgetown is ruby framework that specialized in content management and authoring, a new contender in Jamstack platform. It was supposed to be the successor of the already old Jekyll. The idea is bringing convenient platform like Jekyll but with more modern and robust environment.
It combines the best experience of ruby, javascript and markdown together to create convenient blogging platform. Currently it is still not mature enough compared to other giants like Next JS but it is already showing great promise.

Bridgetown support static sites generation, server side rendering (helped by [Roda](https://github.com/jeremyevans/roda)) and even can be integrated with javascript framework like React, Vue and etc. For basic templating languages there are liquid, erb or serbea (new template languange that combines the latter). 
Even without using js frameworks, you can build nice complex sites by leveraging partials, ruby component, and even [ViewComponent](https://github.com/ViewComponent/view_component). It also supports css frameworks like Tailwind, Bootstrap, Bulma and etc, thought there may be few gotchas that still need to be adressed when you using css tools that is not officially supported.
What's more, the core functionality of Bridgetown can be extended by using plugins be it official or community created, although the numbers can be improved. Currently the community is still growing and there may be cooler and more convenient plugins built by the communities.

Check out the [Bridgetown docs](https://www.bridgetownrb.com/) for more info about its features and current state of development.

## Why Bridgetown?

First and foremost I was a fan of Ruby. Before knowing Ruby, I was user of Javascript, at that time I was exhausted by javascript massive ecosystem, and the notorious Typescript (don't get me wrong, it is great). 
Then by chance, I stumbled upon Ruby. By the convenience of its dynamic typing and elegant syntax's I fell in love. It is not perfect thought, because it is interpreted language it suffers in performance. Although compared to early versions of the language, there are many improvements in the current versions, it still can't be compared to javascript performance and efficiencies.
Well in most cases, you don't need to mind the difference, it is fast enough for most of use cases.

Secondly, because the framework embrace the principle of *Convention over Configuration*. Adhering to that, Bridgetown aiming to as concise as possible in configuration yet still extendable when user need more. 
This way, most users that starting to use Bridgetown will not be overwhelmed by what to do what to configure in their codebase. You just need to move on and write some content.

Third, it supports markdown as contents out of the box, and it was great! By default Bridgetown use kramdown as markdown renderer.
It is fast and support many different features of markdown notations. If you are programmer and occasionally write code in your blog, you just need to create code block, specify the language and bam! your code is served beautifully.

> But, what if i want to use CMS for managing my content?

No worries son! Bridgetown support CMS by using its official plugins or communities (don't worry, Notion is supported too). Feeling little gutsy? you can always generate your content programmatically by providing endpoint for Bridgetown to get your contents.

Now it is your turn to try it and see if you like it or not.