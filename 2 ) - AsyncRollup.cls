trigger OpportunityAfterInsertTrigger on Opportunity (after insert) {

    Set<Id> accountIds = new Set<Id>();

    for (Opportunity opp : Trigger.new) {
        if (opp.AccountId != null) {
            accountIds.add(opp.AccountId);
        }
    }

    // Enqueue only once (bulk-safe)
    if (!accountIds.isEmpty()) {
        System.enqueueJob(new AccountOpportunityTotalQueueable(accountIds));
    }
}
//---------------------------------------------------------------------------------------------------------
public class AccountOpportunityTotalQueueable implements Queueable {

    private Set<Id> accountIds;

    public AccountOpportunityTotalQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {

        // Aggregate total Opportunity Amount per Account
        Map<Id, Decimal> accountToTotalAmount = new Map<Id, Decimal>();

        for (AggregateResult ar : [
            SELECT AccountId accId, SUM(Amount) totalAmount
            FROM Opportunity
            WHERE AccountId IN :accountIds
            GROUP BY AccountId
        ]) {
            accountToTotalAmount.put(
                (Id) ar.get('accId'),
                (Decimal) ar.get('totalAmount')
            );
        }

        // Prepare Account updates
        List<Account> accountsToUpdate = new List<Account>();

        for (Id accId : accountToTotalAmount.keySet()) {
            accountsToUpdate.add(new Account(
                Id = accId,
                Total_Opportunity_Amount__c = accountToTotalAmount.get(accId)
            ));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}
//-------------------------------------------------------------------------------------------------------
/*
Question:
When Opportunity records are created, update the parent Account with the
total Opportunity Amount using Queueable Apex.
The trigger must remain bulk-safe and delegate all business logic to Queueable Apex.
*/
