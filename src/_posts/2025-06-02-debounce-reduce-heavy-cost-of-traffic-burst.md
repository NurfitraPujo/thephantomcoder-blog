---
layout: post
title: "Debounce: Reduce Costly Traffic Burst"
date: 2025-06-02 07:00:00 +0700
categories: updates
published: false
tags: ['debounce', 'software architecture', 'design patterns', 'high traffic']
description: |
  'When your userbase scales up, sometimes you will notice that some operations can be quite costly when hit frequently during high traffic. Debounce pattern can help reduce the cost by merging multiple costly request into one, effectively reducing the load of the system.
---

A basic good ol' CRUD app can take your startup or company very far, so your team can focus on building what truly matters for your users. However, when your userbase scales, there are some operations that can be quite costly on high traffic. Some company may have very high budget on their tech expenditures, some may not, thats why it is important to know what can we do to reduce our system cost. 