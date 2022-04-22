pragma solidity 0.8.7;


interface ICairoVerifier {
    function isValid(bytes32) external view returns (bool);
}

contract DebtAllocator {
    // TODO: update to mainnet verifier
    ICairoVerifier public cairoVerifier = ICairoVerifier(0xAB43bA48c9edF4C2C4bB01237348D1D7B28ef168);

    mapping(address => bytes32[]) public strategyCheckdata;
    // TODO: can move address to first element of strategyCheckdata
    mapping(address => address[]) public strategyContracts;
    address[] public strategies;
    bytes32 public strategiesHash = 0x0;
    bytes32 public cairoProgramHash = 0x0;
    
    uint256 public currentAPY;
    uint256 public lastUpdate;

    uint256 public stalePeriod = 24 * 3600;
    uint256 public staleSnapshotPeriod = 3 * 3600;

    function updateCairoProgramHash(bytes32 _cairoProgramHash) external {
        cairoProgramHash = _cairoProgramHash;
    }

    function addStrategy(address strategy, address[] calldata contracts, bytes32[] calldata checkdata) {
        strategies.push(strategy);
        require(contracts.length == checkdata.length);
        // TODO: require new strategy 
        address[] memory _strategies = strategies;
        strategiesHash = keccak256(abi.encodePacked(strategies));

        for(uint256 i; i < contracts.length; i++) {
            strategyContracts[strategy].push(contracts[i]);
            strategyCheckdata[strategy].push(checkdata[i]);
        }
    }

    // TODO: add function to remove strategy

    function saveSnapshot(address[] memory _strategies) external {
        // TODO: take actual snapshot (this is old code)
        // Check inputs are still valid
        // NOTE: index of inputs (as they are 1D array covering all strategies inputs (2D data)
        bytes32 strategiesHash_ = keccak256(abi.encodePacked(_strategies));
        require(strategiesHash == strategiesHash_, "INVALID_STRATEGIES");
       // uint256 ii;
       // for(uint256 i; i < _strategies.length; i++) {
       //     address strategy = _strategies[i];
       //     bytes32[] memory checkdata = strategyCheckdata[strategy];
       //     address[] memory contracts = strategyContracts[strategy];
       //     for(uint256 j; j < inputCounts[i]; j++) {
       //         ii++;
       //         address contract = contracts[j];
       //         (bool success, bytes memory data) = contract.call(checkdata[j+1]);

       //         // TODO: add results to inputhash
       //     }
       // }

        // TODO: REMOVE. inputHash should be the hash of above's input
        inputHash = 0x1;
        snapshots[inputHash] = Snapshot(
            true,
            block.timestamp
        );
    }

    function verifySolution(bytes32[] memory programOutput) external {
        // NOTE: we add the inputs as outputs to be able to check they were right
        (bytes32 _inputHash, uint256 _newSolution, address[] memory _strategies, uint256[] memory _debtRatios) = parseProgramOutput(programOutput);
        bytes32 strategiesHash_ = keccak256(abi.encodePacked(_strategies));
        bytes32 outputHash = keccak256(abi.encodePacked(_inputHash, _strategies, _debtRatio, _newSolution));
        bytes32 fact = keccak256(abi.encodePacked(cairoProgramHash, outputHash));

        // Used snapshot is valid and not stale
        Snapshot memory ss = snaptshots[inputHash];
        require(ss.done && ss.timestamp + staleSnapshotPeriod < block.timestamp, "INVALID_INPUTS");

        // Script was resolved for the right strategies
        require(strategiesHash == strategiesHash_, "INVALID_SOLUTION");

        // Solution arrays match length
        require(_strategies.length == _debtRatios.length, "INVALID_SOLUTION_0");

        // Check with cairoVerifier
        require(cairoVerifier.isValid(fact), "MISSING_CAIRO_PROOF");

        // Check output is better than previous solution 
        // or no one has improven it in stale period (in case market conditions deteriorated)
        require(_newSolution > currentAPY || block.timestamp - lastUpdate >= stalePeriod, "WRONG_SOLUTION");

        currentAPY = _newSolution;
        lastUpdate = block.timestamp;
    }

    function parseProgramOutput(bytes32[] memory programOutput) internal returns (bytes32 _inputHash, uint256 _newSolution, address[] memory _strategies, uint256[] memory _debtRatios) {
        // TODO: optimize with bit packing / shifting
        _inputHash = bytes32(programOutput[0]);
        _inputHash |= bytes32(programOutput[1]) >> 128;

        _newSolution = uint256(programOutput[2]);

        uint256 numStrats = uint256(programOutput[3]);
        _strategies = new address[](numStrats);
        _debtRatios = new uint256[](numStrats);

        // TODO: optimize: we can pack strat + debtRatio in a single bytes32 slot (address + uint96)
        for(uint256 i; i < numStrats; i++) {
            _strategies[i] = address(programOutput[2*i+4]);
            _debtRatios[i] = uint256(programOutput[2*i+5]);
        }
    }
}

