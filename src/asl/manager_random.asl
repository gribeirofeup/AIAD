// Agent manager_random in project pows

/* Initial beliefs and rules */

beggining.

/* Initial goals */

// join the game
!join.

/* Plans */

+!join : beggining <- 
	-beggining;
	join(manager);
	+canNegotiation.

/*Negotiation phase*/

//React to state change to negotiation
+state(negotiation):canNegotiation <-
	.abolish(didPhase(_,_));
	.abolish(propose(_,_,_));
	+canAuction;
	-canNegotiation;
	!startEA;
	+canInvestors.

//Send to all investors the companies i'm selling
+!startEA : true <-
	.findall(Name,player(investor,Name,_),LI);
	.my_name(Me);
	.print("I'm open for proposals!");
	for(owns(Me,Comp)){
		.send(LI,tell,selling(Comp,0,1));
	}.
	
@pb1[atomic]
+propose(Comp,_,Phase) : not didPhase(Comp,Phase) & state(negotiation) & .my_name(Me) & owns(Me,Comp) <-
	+didPhase(Comp,Phase);
	//wait for all proposals
	.wait(200);
	!handlePropose(Comp,Phase);
	.abolish(propose(Comp,_,Phase));
.
	
+!handlePropose(Comp,Phase) : state(negotiation) <-
	.findall(b(V,A),propose(Comp,V,Phase)[source(A)],List);
	.findall(A,propose(Comp,_,Phase)[source(A)],ListBuyers);
	.length(List,L);
	if(L == 1){
		.max(List,b(V,W));
		.print("Winner of company ", Comp," is ",W, " with an offer of ",V);
		.my_name(Me);
		acceptProposal(W,Me,Comp,V);
	}
	if(not L == 1){
		.print("I received ", L, " proposals for the company ", Comp, ", trying again");
		.max(List,b(V,W));
		//Price has to be bigger than previously biggest offer
		.send(ListBuyers,tell,selling(Comp,V,Phase+1));
	}.
+!handlePropose(Comp,Phase) : not state(negotiation).

/*Investors phase*/

+state(investors):canInvestors <-
	+canNegotiation;
	-canInvestors;
	//Nothing to do here
	+canManagers.
	
/*Managers phase*/

+state(managers):canManagers <-
	+canInvestors;
	-canManagers;
	//Nothing to do here
	+canPayment.

/*Payment phase*/

+state(payment):canPayment <-
	+canManagers;
	-canPayment;
	!payManag;
	+canAuction.

+!payManag :.my_name(Me) & player(_,Me,Cash) & .count(owns(Me,_),NC) & Cash < NC * 10000 <-
	.findall(Company,owns(Me,Company),List);
	.shuffle(List,List2);
	.nth(0,List2,ToSell);
	sellCompany(Me,ToSell);
	.print("Sold company ",ToSell, " for 5000");
	.wait(20);
	!payManag
.
+!payManag :.my_name(Me) & player(_,Me,Cash) & .count(owns(Me,Company),NC) & Cash >= NC * 10000 <-
	for(owns(Me,Company)){
		payFee(Me,10000);
		.print("Payed fee for owning the company ",Company);
	}
.
/*Auction phase*/

+state(auction):canAuction <-
	+canPayment;
	-canAuction;
	//Code
	+canNegotiation.

+aucStart[source(S)] <-
	!handleAuc(S);
	.abolish(aucStart).
	
+!handleAuc(Game) : auction(Company,Color,Mult) & .my_name(Me) & player(_,Me,Cash) <-
	.random(N);
	N2 = N*100;
	if(N < 60){
		.random(Rand);
		Value = (Rand*20000+15000)*Mult;
		if(Value < Cash){
			.broadcast(tell,place_bid(Value))
		}
	}
.
	