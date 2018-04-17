pragma solidity ^0.4.21;

    contract CrowdFunding {

    // 投資家
    struct Investor {
        address addr;   // 投資家のアドレス
        uint amount;    // 投資額
    }

    // 投資家管理用のマップ（だけど、uintをkeyに持つと配列っぽくつかえる）
    // publicのため、getterが自動生成
    // cf.investors(0)[1] で投資額にアクセスできる
    mapping (uint => Investor) public investors;

    address public owner;       // コントラクトのオーナー
    uint public numInvestors;   // 投資家の数（カウンタ）
    uint public deadline;       // 締切（UnixTime）
    string public status;       // キャンペーンのステータス
    bool public ended;          // キェンペーンが終了しているか否か
    uint public goalAmount;     // 投資の目標額
    uint public totalAmount;    // 投資の総額

    // 関数実行アドレスが、コントラクトオーナーかチェック
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // constructor
    function CrowdFunding(uint _duration, uint _goalAmount) public {
        owner = msg.sender;

        // 締切をUnixTimeで設定
        deadline = now + _duration;
        
        goalAmount = _goalAmount;
        status = "Funding";
        ended = false;
        numInvestors = 0;
        totalAmount = 0;
    }

    // 投資する際に呼び出される関数
    function fund() payable public {
        // キャンペーンが終わっていれば処理中断
        require(!ended);

        // 投資家情報を登録していく
        Investor storage inv = investors[numInvestors++];
        inv.addr = msg.sender;
        inv.amount = msg.value;
        totalAmount += inv.amount;
    }

    // 目標額に達したか確認
    // また、キャンペーンの成功/失敗に応じたetherの送金を行う
    function checkGoalReached() public onlyOwner {
        require(!ended);
        
        // 現在時刻が、締切よりも前だったら処理中断
        require(now >= deadline);

        if(totalAmount >= goalAmount) {     // 投資総額が、目標額に達した場合
            status = "Campaign Succeeded";
            ended = true;

            // オーナーにコントラクト内の全etherを送金
            if(!owner.send(address(this).balance)){
                revert();   // 失敗したら全処理を戻す
            }
        } else {    // 目標額に達しなかった場合
            status = "Campaign Failed";
            ended = true;

            // 投資家毎に、etherを返金する
            for(uint i = 0; i <= numInvestors; i++) {
                if(!investors[i].addr.send(investors[i].amount)) {
                    revert();
                }
            }
        }
    }

    // コントラクトオーナーのみがkill可能
    function kill() public onlyOwner {
        selfdestruct(owner);
    }

}