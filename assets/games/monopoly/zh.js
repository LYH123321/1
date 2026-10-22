/* ============================================================
 * zh.js — 大富翁中文叠加层
 * 纯叠加补丁：不改 monopoly.js / index.html 任何一行，
 * 在 index.html 最后加载本文件即可。
 * 原理：
 *   1) 劫持 alert/confirm/prompt，英文→中文即时翻译
 *   2) DOM 就绪后批量替换按钮 value / 文本节点 / title 属性
 *   3) 拦截 popup() 的 innerHTML 注入做翻译
 * 上游：intrepidcoder/monopoly (MIT)
 * ============================================================ */
(function () {
    'use strict';

    var T = {
        // ---- 按钮 ----
        'Start Game': '开始游戏',
        'Roll Dice': '掷骰子',
        'Resign': '认输',
        'Buy': '购买',
        'Manage': '管理',
        'Trade': '交易',
        'Buy house': '买房子',
        'Sell house': '卖房子',
        'Mortgage': '抵押',
        'View stats': '查看统计',
        'Propose Trade': '提议交易',
        'Cancel Trade': '取消交易',
        'Accept Trade': '接受交易',
        'Reject Trade': '拒绝交易',
        'Bid': '出价',
        'Pass': '跳过',
        'Exit Auction': '退出拍卖',
        'OK': '确定',
        'Human': '人类',
        'AI (Test)': 'AI（测试）',
        // ---- 颜色 ----
        'Aqua': '青色', 'Black': '黑色', 'Blue': '蓝色', 'Fuchsia': '紫红',
        'Gray': '灰色', 'Green': '绿色', 'Lime': '青柠', 'Maroon': '栗色',
        'Navy': '藏青', 'Olive': '橄榄', 'Orange': '橙色', 'Purple': '紫色',
        'Red': '红色', 'Silver': '银色', 'Teal': '水鸭青', 'Yellow': '黄色',
        // ---- 静态 UI 文本 ----
        'Monopoly': '大富翁',
        'T I T L E   D E E D': '房 产 契 约',
        'RENT': '租金',
        'With 1 House': '1 栋房子',
        'With 2 Houses': '2 栋房子',
        'With 3 Houses': '3 栋房子',
        'With 4 Houses': '4 栋房子',
        'With HOTEL': '带酒店',
        'Mortgage Value': '抵押价值',
        'Houses cost': '房子价格',
        'Hotels,': '酒店，',
        'plus 4 houses': '外加 4 栋房子',
        'MORTGAGED': '已抵押',
        'Mortgage Value': '抵押价值',
        'Select number of players.': '选择玩家人数。',
        'Player': '玩家',
        'Player name': '玩家名称',
        'Player color': '玩家颜色',
        'Choose whether this player is controled by a human or by the computer.': '选择该玩家由人类还是电脑控制。',
        'Note: Refreshing this page or navigating away from it may end your game without warning.': '注意：刷新或离开本页可能会在无警告的情况下结束游戏。',
        'Note: This page will not function without JavaScript.': '注意：本页没有 JavaScript 将无法运行。',
        'Refresh this page to start a new game.': '刷新本页开始新游戏。',
        'Close': '关闭',
        'Die': '骰子',
        'Begin playing.': '开始游戏。',
        'View a pop-up window that shows a list of each player\'s properties.': '弹出窗口显示每位玩家的地产列表。',
        'Roll the dice and move your token accordingly.': '掷骰子并移动棋子。',
        'If you cannot pay your debt then you must resign from the game.': '无法还债则必须退出游戏。',
        'Enter amount to exchange with the other player.': '输入与对方交换的金额。',
        'Exchange the money and properties that are checked above.': '交换上面勾选的金钱与地产。',
        'Cancel the trade.': '取消交易。',
        'Accept the proposed trade.': '接受提议的交易。',
        'Reject the proposed trade.': '拒绝提议的交易。',
        'Exchange property with other players.': '与其他玩家交换地产。',
        'View, mortgage, and improve your property.': '查看、抵押并改良你的地产。',
        'View alerts and buy the property you landed on.': '查看提示并购买你落脚处的地产。',
        'Available buildings': '可用建筑',
        'Enter an amount to bid on': '输入对以下地产的出价金额',
        'Place your bid.': '出价。',
        'Skip bidding this time.': '本次不出价。',
        'Stop bidding on': '停止对以下地产出价',
        'Stop bidding on': '停止出价',
        'Buy': '购买',
        'Unmortgage': '赎回',
        // ---- monopoly.js 内长句（弹窗/日志） ----
        'collected a $200 salary for passing GO.': '经过起点，领取 $200 工资。',
        'paid the $50 fine to get out of jail.': '缴纳 $50 罚款出狱。',
        'rolled doubles to get out of jail.': '掷出 doubles 出狱。',
        'was sent directly to jail.': '直接被送进监狱。',
        'Go to jail. Go directly to Jail. Do not pass GO. Do not collect $200.': '进监狱。直接进监狱，不得经过起点，不得领取 $200。',
        'to Chance.': '到机会格。',
        'to Community Chest.': '到公益金格。',
        'is bankrupt.': '破产了。',
        'is bankrupt. All of its assets will be turned over to': '破产。所有资产将转交给',
        'landed on': '落脚于',
        'rolled': '掷出',
        'rolled doubles three times in a row.': '连续三次掷出 doubles。',
        'paid $': '支付 $',
        'received $': '收到 $',
        'lost $': '损失 $',
        'bought ': '购买了',
        'mortgaged ': '抵押了',
        'unmortgaged ': '赎回了',
        'placed a house on': '在……上盖了 1 栋房子',
        'placed a hotel on': '在……上盖了酒店',
        'sold a house on': '在……上卖了 1 栋房子',
        'sold the hotel on': '卖了……上的酒店',
        'rent to': '租金付给',
        'exited the auction.': '退出拍卖。',
        'passed.': '跳过。',
        'bid $': '出价 $',
        'more to buy': '还差……才能购买',
        'more to buy a house for': '还差……才能给……买房子',
        'more to buy a hotel for': '还差……才能给……买酒店',
        'more to unmortgage': '还差……才能赎回',
        'does not have $': '没有 $',
        'has no properties to trade.': '没有可交易的地产。',
        'has proposed a trade with you,': '向你提议交易，',
        'has accepted your offer.': '接受了你的提议。',
        'has declined your offer.': '拒绝了你的提议。',
        'has proposed a counteroffer.': '提出了还价。',
        'initiated a trade with': '向……发起交易',
        'in the trade.': '在交易中。',
        '. Property is mortgaged; no rent was collected.': '。该地产已抵押；不收租金。',
        '. You may accept, reject, or modify the offer.': '。你可以接受、拒绝或修改提议。',
        'are you sure you want to mortgage': '确定要抵押',
        ', are you sure you want to mortgage': '，确定要抵押',
        'One or more properties must be selected in order to trade.': '交易必须至少选择一处地产。',
        'All 12 hotels are owned. You must wait until one becomes available.': '12 栋酒店已全部被拥有，请等待有可用酒店。',
        'All 32 houses are owned. You must wait until one becomes available.': '32 栋房子已全部被拥有，请等待有可用房子。',
        'Are you sure you want to resign?': '确定要认输吗？',
        'congratulations': '恭喜',
        'Congratulations': '恭喜',
        'Auction': '拍卖',
        'Highest Bid = $': '最高出价 = $',
        'it is your turn to bid.': '轮到你出价了。',
        'Unmortgage': '赎回',
        ' for $': '，价格 $',
        'Card must be turned this side up if property is mortgaged': '地产抵押时契约必须正面朝上',
        'If a player owns ALL the Lots of any Color-Group, the rent is Doubled on Unimproved Lots in that group.': '若玩家拥有同色组全部地产，该组未改良地产的租金翻倍。',
        'interest on the mortgaged properties received from': '从……收到的抵押地产利息',
        'interest on the mortgaged properties you received from': '你从……收到的抵押地产利息',
        ' collected ': ' 收集了 ',
        'Use "Get Out of Jail Free" card.': '使用"免狱卡"。',
        'Use Card': '使用卡片',
        'Pay $50 fine': '缴纳 $50 罚款',
        'Use "Get Out of Jail Free" card.': '使用"免狱卡"。',
        'spots)': '格)',
        ' houses.': ' 栋房子。',
        'dosen\'t have any properties.': '没有任何地产。',
        'You may unmortgage any of the following properties, interest free, by clicking on them. Click OK when finished.': '你可以点击以下地产免费赎回。完成后点击确定。'
    };

    // ---- 句子级翻译（正则替换，处理拼接文本） ----
    var RULES = [
        [/collected a \$200 salary for passing GO\./g, '经过起点，领取 $200 工资。'],
        [/paid the \$50 fine to get out of jail\./g, '缴纳 $50 罚款出狱。'],
        [/rolled doubles to get out of jail\./g, '掷出 doubles 出狱。'],
        [/was sent directly to jail\./g, '直接被送进监狱。'],
        [/Go to jail\. Go directly to Jail\. Do not pass GO\. Do not collect \$200\./g, '进监狱。直接进监狱，不得经过起点，不得领取 $200。'],
        [/ is bankrupt\. All of its assets will be turned over to /g, ' 破产。所有资产将转交给 '],
        [/ is bankrupt\./g, ' 破产了。'],
        [/\. Property is mortgaged; no rent was collected\./g, '。该地产已抵押；不收租金。'],
        [/\. You may accept, reject, or modify the offer\./g, '。你可以接受、拒绝或修改提议。'],
        [/One or more properties must be selected in order to trade\./g, '交易必须至少选择一处地产。'],
        [/All 12 hotels are owned\. You must wait until one becomes available\./g, '12 栋酒店已全部被拥有，请等待有可用酒店。'],
        [/All 32 houses are owned\. You must wait until one becomes available\./g, '32 栋房子已全部被拥有，请等待有可用房子。'],
        [/Are you sure you want to resign\?/g, '确定要认输吗？'],
        [/rolled doubles three times in a row\./g, '连续三次掷出 doubles。'],
        [/exited the auction\./g, '退出拍卖。'],
        [/has no properties to trade\./g, '没有可交易的地产。'],
        [/has accepted your offer\./g, '接受了你的提议。'],
        [/has declined your offer\./g, '拒绝了你的提议。'],
        [/has proposed a counteroffer\./g, '提出了还价。'],
        [/has proposed a trade with you,/g, '向你提议交易，'],
        [/\bBuy \$/g, '购买 $'],
        [/\bBuy\b/g, '购买'],
        [/\bPass\b/g, '跳过'],
        [/\bManage\b/g, '管理'],
        [/\bTrade\b/g, '交易'],
        [/\bMortgage\b/g, '抵押'],
        [/\bUnmortgage\b/g, '赎回'],
        [/\bBid\b/g, '出价'],
        [/\bExit Auction\b/g, '退出拍卖'],
        [/\bRoll Dice\b/g, '掷骰子'],
        [/\bStart Game\b/g, '开始游戏'],
        [/\bView stats\b/g, '查看统计'],
        [/\bResign\b/g, '认输'],
        [/\bPropose Trade\b/g, '提议交易'],
        [/\bCancel Trade\b/g, '取消交易'],
        [/\bAccept Trade\b/g, '接受交易'],
        [/\bReject Trade\b/g, '拒绝交易'],
        [/\bBuy house\b/g, '买房子'],
        [/\bSell house\b/g, '卖房子'],
        [/\bPlayer (\d)\b/g, '玩家 $1'],
        [/\bHuman\b/g, '人类'],
        [/\bAI \(Test\)\b/g, 'AI（测试）'],
        [/\bAuction\b/g, '拍卖'],
        [/\bHighest Bid = \$/g, '最高出价 = $'],
        [/\bChance\b/g, '机会'],
        [/\bCommunity Chest\b/g, '公益金'],
        [/\bHotel\b/g, '酒店'],
        [/\bHouse\b/g, '房子'],
        [/\bMortgaged\b/g, '已抵押'],
        [/\bGO\b/g, '起点']
    ];

    function translateText(s) {
        if (!s || typeof s !== 'string') return s;
        if (T[s] !== undefined) return T[s];
        var r = s;
        for (var i = 0; i < RULES.length; i++) {
            r = r.replace(RULES[i][0], RULES[i][1]);
        }
        return r;
    }

    // ---- 劫持 alert/confirm/prompt ----
    var _alert = window.alert;
    window.alert = function (msg) { return _alert.call(window, translateText(String(msg))); };
    var _confirm = window.confirm;
    window.confirm = function (msg) { return _confirm.call(window, translateText(String(msg))); };
    var _prompt = window.prompt;
    window.prompt = function (msg, def) { return _prompt.call(window, translateText(String(msg)), def); };

    // ---- 劫持 popup：monopoly.js 用 popup(html) 注入弹窗 ----
    if (typeof window.popup === 'function') {
        var _popup = window.popup;
        window.popup = function (html) {
            if (typeof html === 'string') html = translateText(html);
            return _popup.call(window, html);
        };
    }

    // ---- DOM 批量替换 ----
    function patchDom() {
        // 按钮 value / title
        var inputs = document.querySelectorAll('input[type=button], input[type=submit], button');
        inputs.forEach(function (el) {
            var v = el.value || el.textContent;
            if (v) {
                var nv = translateText(v.trim());
                if (nv !== v) {
                    if (el.value !== undefined && el.value) el.value = nv;
                    else el.textContent = nv;
                }
            }
            var t = el.title || el.getAttribute('title');
            if (t) {
                var nt = translateText(t);
                if (nt !== t) el.setAttribute('title', nt);
            }
        });
        // option 文本
        var opts = document.querySelectorAll('option');
        opts.forEach(function (el) {
            var nv = translateText(el.textContent.trim());
            if (nv !== el.textContent) el.textContent = nv;
        });
        // 顶部静态文本节点（setup / noF5 / noscript / refresh / deed）
        var staticIds = ['noscript', 'refresh', 'noF5', 'setup', 'deed-normal', 'deed-mortgaged', 'deed-special'];
        staticIds.forEach(function (id) {
            var el = document.getElementById(id);
            if (!el) return;
            walkTextNodes(el);
        });
        // 通用 title 属性
        var titled = document.querySelectorAll('[title]');
        titled.forEach(function (el) {
            var t = el.getAttribute('title');
            if (t) {
                var nt = translateText(t);
                if (nt !== t) el.setAttribute('title', nt);
            }
        });
        // moneybar 玩家名（Player 1..8）
        for (var i = 1; i <= 8; i++) {
            var mn = document.getElementById('p' + i + 'moneyname');
            if (mn) mn.textContent = translateText(mn.textContent);
        }
        // 观察弹窗内容变化（popup 动态注入）
        var pt = document.getElementById('popuptext');
        if (pt && window.MutationObserver) {
            var obs = new MutationObserver(function (muts) {
                muts.forEach(function (m) {
                    if (m.type === 'childList' || m.type === 'characterData') walkTextNodes(pt);
                });
            });
            obs.observe(pt, { childList: true, subtree: true, characterData: true });
        }
        // stats 弹窗
        var st = document.getElementById('statstext');
        if (st && window.MutationObserver) {
            var obs2 = new MutationObserver(function (muts) {
                muts.forEach(function () { walkTextNodes(st); });
            });
            obs2.observe(st, { childList: true, subtree: true, characterData: true });
        }
    }

    function walkTextNodes(root) {
        var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null, false);
        var nodes = [];
        var n;
        while ((n = walker.nextNode())) nodes.push(n);
        nodes.forEach(function (tn) {
            var nv = translateText(tn.nodeValue);
            if (nv !== tn.nodeValue) tn.nodeValue = nv;
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', patchDom);
    } else {
        patchDom();
    }
    // setup() 之后界面整体生成，延迟再扫一遍
    window.addEventListener('load', function () {
        setTimeout(patchDom, 300);
        setTimeout(patchDom, 1500);
    });
})();
