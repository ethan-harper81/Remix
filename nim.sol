// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

// Tools:
// In this assignment we will be programming in Ethereum with Solidity.
// You should be familiar with solidity due to the "cryptozombies" tutorials.
// You can use remix.ethereum.org to gain access to a Solidity programming environment,
// and install the metamask.io browser extension to access an ethereum testnet wallet.

// Project:

// Implement the Nim board game (the "misere" version -- if you move last, you lose).
// See https://en.wikipedia.org/wiki/Nim for details about the game, but in essence
// there are N piles (think array length N of uint256) and in each turn a player must 
// take 1 or more items (player chooses) from only 1 pile.  If the pile is empty, of 
// course the player cannot take items from it.  The last player to take items loses.
// Also in our version, if a player makes an illegal move, it loses.

// To implement this game, you need to create a contract that implements the interface 
// "Nim" (see below).

// Nim.startMisere kicks things off.  It is given the addresses of 2 NimPlayer (contracts)
// and an initial board configuration (for example [1,2] would be 2 piles with 1 and 2 items in them).

// Your code must call the nextMove API alternately in each NimPlayer contract to receive 
// that player's next move, ensure its legal, apply it, and see if the player lost.
// Player a gets to go first.
// If the move is illegal, or the player lost, call the appropriate Uxxx functions
// (e.g. Uwon, Ulost, UlostBadMove) functions for both players, and award the winner
// all the money sent into "startMisere" EXCEPT your 0.001 ether fee for hosting the game.

// I have supplied an example player.
// You should submit your solution to Gradescope's auto-tester.  The tests in
// Gradescope are representative of the final tests we will apply to your submission,
// but are not comprehensive.

// To submit to Gradescope, create a zip file with a single file named nim.sol in it (no subdirectories!).
// This is an example Makefile to do this on Linux, if your work is in a subdirectory called "submission":
// nim_solution.zip: submission/nim.sol
//	(cd submission; 7z a ../nim_solution.zip nim.sol)


// TESTING IS A CRITICAL PART OF THIS ASSIGNMENT.
// You must think about how the game can be exploited and write your own
// misbehaving players to attack your own Nim game!

// If you rely on the autograder to be your tests, you will waste a huge amount
// of your own time because the autograder takes a while to run.

// Leave your tests in your submitted nim.sol file either commented out or as
// separate contracts.  The auto-graded points are not the final grade.  The
// graders will look at the quality of your tests and code and may bump you
// up/down based on our assessment of it.

// Good luck! You've got this!


interface NimPlayer
{
    // Given a set of piles, return a pile number and a quantity of items to remove
    function nextMove(uint256[] calldata piles) external returns (uint, uint256);
    // Called if you win, with your winnings!
    function Uwon() external payable;
    // Called if you lost :-(
    function Ulost() external;
    // Called if you lost because you made an illegal move :-(
    function UlostBadMove() external;
}


interface Nim
{
    // fee is 0.001 ether, award the winner the rest
    function startMisere(NimPlayer a, NimPlayer b, uint256[] calldata piles) payable external;  
}


contract NimBoard is Nim
{

    function illegalMove(uint256[] memory piles, uint pile, uint256 quantity) internal pure returns(bool){
        if(quantity == 0) return true; //take nothing
        if(piles[pile] == 0) return true; //take from empty pile
        if(quantity > piles[pile]) return true; //take more than is in pile
        if(pile >= piles.length) return true; //take from a pile out of range

        return false;
    }

    function checkEmpty(uint256[] memory piles) internal pure returns(bool){
        for (uint i = 0; i < piles.length; i++) 
        {
              if(piles[i] != 0) return false; 
        }
    
        return true;

    }

    function startMisere(NimPlayer a, NimPlayer b, uint256[] calldata piles) override payable external{
        //copy array

        uint256[] memory newpiles = new uint256[](piles.length);
        for(uint i = 0; i < piles.length; i++){
            newpiles[i] = piles[i];
        }

        bool playerATurn = true;

        while (true) {
            NimPlayer currentPlayer = playerATurn ? a : b;
            NimPlayer opponentPlayer = playerATurn ? b : a;

            try currentPlayer.nextMove(newpiles) returns (uint pile, uint256 quantity) {
                if (illegalMove(newpiles, pile, quantity)) {
                    // Illegal move
                    currentPlayer.UlostBadMove();
                    opponentPlayer.Uwon{value: msg.value - 0.001 ether}();
                    return;
                }

                newpiles[pile] -= quantity;

                if (checkEmpty(newpiles)) {
                    // Current player loses as the board is empty
                    currentPlayer.Ulost();
                    opponentPlayer.Uwon{value: msg.value - 0.001 ether}();
                    return;
                }
            } catch {
                // Handle any unexpected failures
                currentPlayer.UlostBadMove();
                opponentPlayer.Uwon{value: msg.value - 0.001 ether}();
                return;
            }

            playerATurn = !playerATurn;
        }
    }      
        
}


contract TrackingNimPlayer is NimPlayer
{
    uint losses=0;
    uint wins=0;
    uint faults=0;

    // You should pay the player when you call Uwon, BUT I am allowing transfer-only payments here
    // to make things simpler (for example to load the player with funds).
    // This is stuff that was added to Solidity after "crypto-zombies" was made to stop people from
    // accidentally paying into contracts with no withdraw function.
    fallback() external payable {}
    receive() external payable {}

    // Given a set of piles, return a pile number and a quantity of items to remove
    function nextMove(uint256[] calldata) virtual override external returns (uint, uint256)
    {
        return(0,1);
    }
    // Called if you win, with your winnings!
    function Uwon() override external payable
    {
        wins += 1;
    }
    // Called if you lost :-(
    function Ulost() override external
    {
        losses += 1;
    }
    // Called if you lost because you made an illegal move :-(
    function UlostBadMove() override external
    {
        faults += 1;
    }
    
    function results() external view returns(uint, uint, uint, uint)
    {
        return(wins, losses, faults, address(this).balance);
    }
    
}

contract Boring1NimPlayer is TrackingNimPlayer
{
    // Given a set of piles, return a pile number and a quantity of items to remove
    function nextMove(uint256[] calldata piles) override external pure returns (uint, uint256)
    {
        for(uint i=0;i<piles.length; i++)
        {
            if (piles[i]>1) return (i, piles[i]-1);  // consumes all in a pile
        }
        for(uint i=0;i<piles.length; i++)
        {
            if (piles[i]>0) return (i, piles[i]);  // consumes all in a pile
        }
        return(0,0);
    }
}

// struct move{
//     uint pile;
//     uint256 quantity;
// }

// contract TestPlayer is TrackingNimPlayer{
//     uint256[] public moves;
//     uint256 currentMove;

//     constructor(uint256[] memory _moves){
//         for (uint i = 0; i<_moves.length; i++) 
//         {
//             moves.push(_moves[i]);
//         }
//         currentMove = 0;
//     } 

//     function nextMove(uint256[] calldata piles) override external  returns (uint, uint256){
        
//         uint pile = moves[currentMove] / 100;
//         uint quantity = moves[currentMove]%100;
//         currentMove++;
//         return (pile, quantity);
//     }
// }

// //Deploy contract and run any of these functions with 2 finney
// contract TestNim{
//     NimBoard public testBoard;

//     TestPlayer playerA;
//     TestPlayer playerB;

//     function testBadMove_RemoveZeroItems() payable external{
//         uint256[] memory piles =  new uint256[](2);
//         piles[0] = 1;
//         piles[1] = 2;

//         uint256[] memory Amoves = new uint256[](2);
//         Amoves[0] = 1;
//         Amoves[1] = 100;
        
//         uint256[] memory Bmoves = new uint256[](2);
//         Bmoves[0] = 101;
//         Bmoves[1] = 101;

//         playerA = new TestPlayer(Amoves);
//         playerB = new TestPlayer(Bmoves);

//         testBoard = new NimBoard();

//         testBoard.startMisere{value: .002 ether}(playerA, playerB, piles);
//         (,, uint afaulty, ) = playerA.results();
//         (,,,uint bbalance) = playerB.results();
//         require(afaulty == 1, "Expected A to lose by bad move");
//         require(bbalance == .001 ether, "Player B should Have gotten Reward");

//     }

//     function testBadMove_TakeFromEmptyPile() payable external{
//         uint256[] memory piles = new uint[](2);
//         piles[0] = 2;
//         piles[1] = 3;

//         uint256[] memory Amoves = new uint256[](2);
//         Amoves[0] = 101; //one item from pile 2
//         Amoves[1] = 101; //one item from pile 2
        
//         uint256[] memory Bmoves = new uint256[](2);
//         Bmoves[0] = 2; //2 items from pile 1
//         Bmoves[1] = 0; //0 items from pile 1

//         playerA = new TestPlayer(Amoves);
//         playerB = new TestPlayer(Bmoves);

//         testBoard = new NimBoard();

//         testBoard.startMisere{value: .002 ether}(playerA, playerB, piles);

//         (,,,uint balance) = playerA.results();
//         (,,uint faulty,) = playerB.results();
//         require(balance == 0.001 ether, "Player A should have won and gotten reward");
//         require(faulty == 1, "Player B should have lost to a faulty move");
//     }

//     function testBadMove_TakeTooManyItems() payable external{
//         uint256[] memory piles = new uint[](2);
//         piles[0] = 4;
//         piles[1] = 3;

//         uint256[] memory Amoves = new uint256[](2);
//         Amoves[0] = 101; //1 item from pile 2
//         Amoves[1] = 3; //3 item from pile 1
        
//         uint256[] memory Bmoves = new uint256[](2);
//         Bmoves[0] = 2; //2 items from pile 1
//         Bmoves[1] = 102; //2 items from pile 2

//         playerA = new TestPlayer(Amoves);
//         playerB = new TestPlayer(Bmoves);

//         testBoard = new NimBoard();

//         testBoard.startMisere{value: .002 ether}(playerA, playerB, piles);

//         (,,uint faulty,) = playerA.results();
//         (,,,uint balance) = playerB.results();
//         require(balance == 0.001 ether, "Player B should have won and gotten reward");
//         require(faulty == 1, "Player A should have lost to a faulty move");
//     }

//     function testBadMove_TakeFromNonexistantPile() payable external{
//         uint256[] memory piles = new uint[](2);
//         piles[0] = 4;
//         piles[1] = 3;

//         uint256[] memory Amoves = new uint256[](2);
//         Amoves[0] = 101; //1 item from pile 2
//         Amoves[1] = 2; //2 item from pile 1
        
//         uint256[] memory Bmoves = new uint256[](2);
//         Bmoves[0] = 1; //1 items from pile 1
//         Bmoves[1] = 202; //2 items from pile 3 (doesnt exist)

//         playerA = new TestPlayer(Amoves);
//         playerB = new TestPlayer(Bmoves);

//         testBoard = new NimBoard();

//         testBoard.startMisere{value: .002 ether}(playerA, playerB, piles);

//         (,,,uint balance) = playerA.results();
//         (,,uint faulty,) = playerB.results();
//         require(balance == 0.001 ether, "Player A should have won and gotten reward");
//         require(faulty == 1, "Player B should have lost to a faulty move");
//     }

//     function testValidWinB()payable external{
//         uint256[] memory piles = new uint[](3);
//         piles[0] = 4;
//         piles[1] = 3;
//         piles[2] = 1;

//         uint256[] memory Amoves = new uint256[](3);
//         Amoves[0] = 3; //3 item from pile 1
//         Amoves[1] = 102; //2 item from pile 2
//         Amoves[2] = 1;//1 item from pile 1

//         uint256[] memory Bmoves = new uint256[](2);
//         Bmoves[0] = 101; //1 items from pile 2
//         Bmoves[1] = 201; //1 items from pile 3 

//         playerA = new TestPlayer(Amoves);
//         playerB = new TestPlayer(Bmoves);

//         testBoard = new NimBoard();

//         testBoard.startMisere{value: .002 ether}(playerA, playerB, piles);

//         (,uint losses,,) = playerA.results();
//         (,,,uint balance) = playerB.results();
//         require(balance == 0.001 ether, "Player B should have won and gotten reward");
//         require(losses == 1, "Player A should have lost to playing fair");
//     }

//     function testValidWinA()payable external{
//         uint256[] memory piles = new uint[](3);
//         piles[0] = 5;
//         piles[1] = 3;
//         piles[2] = 1;

//         uint256[] memory Amoves = new uint256[](3);
//         Amoves[0] = 3; //3 item from pile 1
//         Amoves[1] = 102; //2 item from pile 2
//         Amoves[2] = 1;//1 item from pile 1

//         uint256[] memory Bmoves = new uint256[](3);
//         Bmoves[0] = 101; //1 items from pile 2
//         Bmoves[1] = 201; //1 items from pile 3 
//         Bmoves[2] = 1; //1 item from pile 1

//         playerA = new TestPlayer(Amoves);
//         playerB = new TestPlayer(Bmoves);

//         testBoard = new NimBoard();

//         testBoard.startMisere{value: .002 ether}(playerA, playerB, piles);

//         (,,,uint balance) = playerA.results();
//         (,uint losses,,) = playerB.results();
//         require(balance == 0.001 ether, "Player A should have won and gotten reward");
//         require(losses == 1, "Player B should have lost to playing fair");
//     }

// }


/*
Test vectors:

deploy your contract NimBoard (we'll call it "C" here)
deploy 2 Boring1NimPlayers, A & B

In remix set the value to 0.002 eth (2 finney) and call
C.startMisere(A,B,[1,1])

A should have 1 win and a balance of 1000000000000000 (0.001 eth)
B should have 1 loss

Now try C.startMisere(A,B,[1,2])
Now A and B should both have 1 win and 1 loss (and B should have gained however many coins you funded the round with)

The above is a pain to click through by hand, except the first few times.
Maybe you could create a contract that tests your Nim contract?
*/
