trigger AccountAfterUpdateTrigger on Account (after update) {

    Set<Id> updatedAccountIds = new Set<Id>();

    for (Account newAcc : Trigger.new) {
        Account oldAcc = Trigger.oldMap.get(newAcc.Id);

        // Proceed only if Phone number is changed and not null
        if (newAcc.Phone != oldAcc.Phone && newAcc.Phone != null) {
            updatedAccountIds.add(newAcc.Id);
        }
    }

    // Call Future method only once (bulk-safe)
    if (!updatedAccountIds.isEmpty()) {
        AccountContactPhoneFutureHandler.updateContactPhones(updatedAccountIds);
    }
}
//-----------------------------------------------------------------------------------
public class AccountContactPhoneFutureHandler {

    /*
    Future Method:
    Updates Phone field on all Contacts related to the given Account Ids
    */
    @future
    public static void updateContactPhones(Set<Id> accountIds) {

        List<Contact> contactsToUpdate = [
            SELECT Id, Phone, Account.Phone
            FROM Contact
            WHERE AccountId IN :accountIds
        ];

        for (Contact con : contactsToUpdate) {
            con.Phone = con.Account.Phone;
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}
//----------------------------------------------------------------------------------------------
/*
Question:
When an Account's Phone number is updated, automatically copy the updated Phone value
to all related Contact records using a Future method.
The solution must be bulk-safe and must not perform DML directly inside the trigger.
*/
