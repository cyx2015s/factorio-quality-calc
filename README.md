# About

I was researching on quality upcycling, so I wrote some lua code to help me calculate the conversion rates and extra buildings needed.

Code in python are generated from the lua code by deepseek.

Refer to the doc in the code for usage.

I will show some use cases in lua below.

```lua
> module = require("scripts.matrix")
> 1 / module.ublm(module.vizk_hvub(0.025*5,0.025*4,4,0.25))[1][5]
1.0 --- The conversion rate when using a 300% productivity recipe, craft and recyle
> 1 / module.ublm(module.vizk_hvub(0.025*5,0.025*4,1.5,0.25))[1][5]
368.63677633813 --- The conversion rate when using a 50% productivity recipe, craft and recyle, all use normal quality quality module 3s, in electromagnetic plant. You get one legendary item every 368.6 items inputed. Ignore the extra recycle at the end.
> 1 / module.jiuu(module.vizk_hvub(0.062*5,0.062*4,1.5,0.25))
1.579215731002 --- The total recipes crafting at stable state. At above condition, 1.57 recipes should be crafted per second, when you input ingredients that can craft 1 second, and you will get 1 / 368 legendary item per second.
> 1 / module.ublm(module.zivr(0.025*2,0.8))[1][5]
384.0 --- A space casino filled with normal quality module outputs 1 legendary asteroid chunk every 384 items inputed.
> 1 / module.ublm(module.zivr(0.062*2,0.8))[1][5] 
47.698631426613 --- A space casino filled with legendary quality module 3s outputs 1 legendary asteroid chunk every 47.7 items inputed.
> 1 / module.ublm(module.zivr(0.025*2,0.8))[3][5]
24.0 --- A space casino filled with normal quality module outputs 1 legendary asteroid chunk every 24 rare ones inputed. You can treat it the same as from normal to rare when quality levels are not all unlocked.
```
