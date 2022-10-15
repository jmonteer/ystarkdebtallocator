//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;


interface ICairoVerifier {
    function isValid(bytes32) external view returns (bool);
}

contract DebtAllocatorTest {

    ICairoVerifier public cairoVerifier = ICairoVerifier(address(0));
    bytes32 public cairoProgramHash = 0x0;

    address[] public strategies;
    uint256[] public debtRatios;

    struct Calculation {
      uint256 operand1;
      uint256 operand2;
      uint256 operation;
   }

    //mapping to get strategy inputs, contracts address+selector
    mapping(address => address[]) public strategyContracts;
    mapping(address => bytes[]) public strategyCheckdata;
    mapping(address => Calculation[]) public strategyCalculation;

    //Some strategies may be risky or involve lock, their allocation should be limited in the vault
    mapping(address => uint16) public strategyMaxDebtRatio;

    // Everyone is free to propose a new solution, the address is stored so the user can get rewarded
    address public proposer;
    uint256 public currentAPY;
    uint256 public lastUpdate;
    uint256 public inputHash;
    mapping(uint256 => uint256) public snapshotTimestamp;

    uint256 public stalePeriod = 24 * 3600;
    uint256 public staleSnapshotPeriod = 3 * 3600;

    constructor(address _cairoVerifier, bytes32 _cairoProgramHash) payable {
        updateCairoVerifier(_cairoVerifier);
        updateCairoProgramHash(_cairoProgramHash);
    }

    event NewSnapshot(uint256[][] dataStrategies, Calculation[][] calculation,uint256 inputHash, uint256 timestamp);
    event NewStrategy(address newStrategy, address[] strategyContracts,bytes[] strategyCheckData);
    event StrategyRemoved(address strategyRemoved);
    event StrategyMaxDebtRatioUpdated(address newStrategy, uint256 newStrategyMaxDebtRatio);
    event NewCairoProgramHash(bytes32 newCairoProgramHash);
    event NewCairoVerifier(address newCairoVerifier);
    event NewStalePeriod(uint256 newStalePeriod);
    event NewStaleSnapshotPeriod(uint256 newStaleSnapshotPeriod);
    event NewSolution(uint256 newApy, uint256[] newDebtRatio, address proposer, uint256 timestamp);

    // TODO: add role based access control to invoke those functions

    function updateCairoProgramHash(bytes32 _cairoProgramHash) public {
        cairoProgramHash = _cairoProgramHash;
        emit NewCairoProgramHash(_cairoProgramHash);
    }

    function updateCairoVerifier(address _cairoVerifier) public {
        cairoVerifier = ICairoVerifier(_cairoVerifier);
        emit NewCairoVerifier(_cairoVerifier);
    }

    function updateStalePeriod(uint256 _stalePeriod) public {
        stalePeriod = _stalePeriod;
        emit NewStalePeriod(_stalePeriod);
    }

    function updateStaleSnapshotPeriod(uint256 _staleSnapshotPeriod) public {
        staleSnapshotPeriod = _staleSnapshotPeriod;
        emit NewStaleSnapshotPeriod(_staleSnapshotPeriod);
    }

    function addStrategy(address strategy, uint16 maxDebtRatio,address[] memory contracts, bytes[] memory checkdata, Calculation[] memory calculations) external {
        strategies.push(strategy);
        require(contracts.length == checkdata.length);
        for(uint256 i; i < contracts.length; i++) {
            strategyContracts[strategy].push(contracts[i]);
            strategyCheckdata[strategy].push(checkdata[i]);
        }

        for(uint256 j; j < contracts.length; j++) {
            strategyCalculation[strategy].push(calculations[j]);
            strategyCalculation[strategy].push(calculations[j]);
        }

        strategyMaxDebtRatio[strategy] = maxDebtRatio;
        emit NewStrategy(strategy, strategyContracts[strategy], strategyCheckdata[strategy]);
    }

    function removeStrategy(uint256 index) external {
        //TODO: assert debtAllocation is nul for this strategy?
        require(strategies.length > 0, "strategy tab is empty");
        require(index < strategies.length && index >= 0, "select an appropriate index");
        // require debtallocation = 0?
        address strategy = strategies[index];
        delete strategyContracts[strategy];
        delete strategyCheckdata[strategy];
        delete strategyCalculation[strategy];
        delete strategyMaxDebtRatio[strategy];
        strategies[index] = strategies[strategies.length-1];
        strategies.pop();
        emit StrategyRemoved(strategy);
    }

    

    //Can't set only view, .call potentially modify state (should not arrive)
    function getStrategiesData() public returns(uint256[][] memory _dataStrategies) {
        uint256[][] memory dataStrategies = new uint256[][](strategies.length);
        for(uint256 i; i < dataStrategies.length; i++) {
            bytes[] memory checkdata = strategyCheckdata[strategies[i]];
            address[] memory contracts = strategyContracts[strategies[i]];
            uint256[] memory dataStrategy = new uint256[](contracts.length);
            for(uint256 j; j < checkdata.length; j++) {
                (bool success, bytes memory data) = contracts[j].call(checkdata[j]);
                require(success == true, "call didn't succeed");
                dataStrategy[j] = uint256(bytes32(data));
            }
            dataStrategies[i] = dataStrategy;
        }
       return(dataStrategies);
    }

    function getStrategiesCalculation() public view returns(Calculation[][] memory _calculationStrategies) {
        Calculation[][] memory calculationStrategies = new Calculation[][](strategies.length);
        for(uint256 i; i < calculationStrategies.length; i++) {
            calculationStrategies[i] = strategyCalculation[strategies[i]];
        }
       return(calculationStrategies);
    }

    function saveSnapshot() external {
        require(strategies.length > 0, "no strategies registered");

        uint256[][] memory dataStrategies = getStrategiesData(); 

        uint256 dataStratTotalLen = 0;
        for(uint256 i; i < dataStrategies.length; i++) {
            dataStratTotalLen += dataStrategies[i].length;
        }

        uint256 index1 = 0;
        uint256[] memory dataStrategiesConcat = new uint256[](dataStratTotalLen);
        for(uint256 k = 0; k < dataStrategies.length; k++) {
            for(uint256 l = 0; l < dataStrategies[k].length; l++) {
                dataStrategiesConcat[index1] = dataStrategies[k][l];
                index1++;
            }
        }

        Calculation[][] memory calculationStrategies = getStrategiesCalculation();
        uint256 calculationStratTotalLen = 0;
        for(uint256 j; j < calculationStrategies.length; j++) {
            calculationStratTotalLen += calculationStrategies[j].length;
        }

        uint256 index2 = 0;
        uint256[] memory calculationStrategiesConcat = new uint256[](calculationStratTotalLen * 3);
        for(uint256 m = 0; m < calculationStrategies.length; m++) {
            for(uint256 n = 0; n < calculationStrategies[n].length; n++) {
                calculationStrategiesConcat[index2] = calculationStrategies[m][n].operand1;
                index2++;
                calculationStrategiesConcat[index2] = calculationStrategies[m][n].operand2;
                index2++;
                calculationStrategiesConcat[index2] = calculationStrategies[m][n].operation;
                index2++;
            }
        }

        inputHash = uint(keccak256(abi.encodePacked(dataStrategiesConcat, calculationStrategiesConcat)));

        snapshotTimestamp[inputHash] = block.timestamp;

        emit NewSnapshot(dataStrategies, calculationStrategies, inputHash, block.timestamp);
    }

    function verifySolution(uint256[] memory programOutput) external returns(bytes32){
        // NOTE: we add the inputs as outputs to be able to check they were right
        (uint256 _inputHash,  uint256[] memory _debtRatios, uint256 _newSolution) = parseProgramOutput(programOutput); 
        bytes32 outputHash = keccak256(abi.encodePacked(programOutput));
        bytes32 fact = keccak256(abi.encodePacked(cairoProgramHash, outputHash));
        
        // Used snapshot is valid and not stale
        // uint256 _snapshotTimestamp = snapshotTimestamp[_inputHash];
       // remove for test
       // require(_inputHash==_inputHash && _snapshotTimestamp + staleSnapshotPeriod < block.timestamp, "INVALID_INPUTS");
       require(_inputHash==_inputHash, "INVALID_INPUTS");


        // check allowed debt ratio
        checkAllowedDebtRatio(_debtRatios);


        // Check with cairoVerifier
        // require(cairoVerifier.isValid(fact), "MISSING_CAIRO_PROOF");

        // Check output is better than previous solution 
        // or no one has improven it in stale period (in case market conditions deteriorated)
        // remove for test 
        //require(_newSolution > currentAPY || block.timestamp - lastUpdate >= stalePeriod, "WRONG_SOLUTION");
        // require(_newSolution > currentAPY, "WRONG_SOLUTION");

        currentAPY = _newSolution;
        debtRatios = _debtRatios;
        lastUpdate = block.timestamp;
        proposer = msg.sender;

        emit NewSolution(_newSolution, _debtRatios, msg.sender, block.timestamp);
        return(fact);
    }

    function parseProgramOutput(uint256[] memory programOutput) public view returns (uint256 _inputHash, uint256[] memory _debtRatios, uint256 _newSolution) {
        uint256 inputHashUint256 = programOutput[0] << 128;
        inputHashUint256 += programOutput[1];
        uint256[] memory newDebtRatios = new uint256[](strategies.length);
        for(uint256 i = 3; i < programOutput.length - 1; i++) {
            // NOTE: skip the 2 first value + array len 
            newDebtRatios[i-3] = programOutput[i];
        }
        return(inputHashUint256, newDebtRatios, programOutput[programOutput.length - 1]);
    }

    function checkAllowedDebtRatio(uint256[] memory debtRatios_) public view {
        for(uint256 i; i < debtRatios_.length; i++) {
            require(debtRatios_[i] <= strategyMaxDebtRatio[strategies[i]],"not allowed debt ratio");
        }
    }
}

