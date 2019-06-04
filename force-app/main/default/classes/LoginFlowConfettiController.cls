public without sharing class LoginFlowConfettiController {

    public Boolean showConfetti { get; private set; }

    public PageReference onLogin() {

		this.showConfetti = false;

        User currentUser = [
        	SELECT
            	Id, Name, LastPasswordChangeDate
            FROM
            	User
            WHERE
            	Id = :UserInfo.getUserId()
        ];

        // Since we can't filter the query by the `Display` field to know
        // who the password reset is for, we need to query for a sufficient
        // number of previous password resets and look for the one for the current user.
        // Ideally, this is the first record in our result set, but it might be a few behind it
        // if a LOT of users reset their passwords at approx. the same time.
        for ( SetupAuditTrail trail : [
            SELECT
            	Id, Action, Display, Section, CreatedDate, CreatedById
            FROM
            	SetupAuditTrail
            WHERE
            	Action IN ( 'resetpassword' )
            	AND
            	CreatedDate <= :currentUser.LastPasswordChangeDate
            	AND
            	CreatedDate >= :currentUser.LastPasswordChangeDate.addDays(-1)
            ORDER BY
            	CreatedDate DESC
            LIMIT
            	200
        ]) {

            Boolean isPasswordResetForCurrentUser = ( trail.Display == ( 'Reset password for user ' + currentUser.Name ) );
            Boolean isPasswordResetByCurrentUser = ( trail.CreatedById == currentUser.Id );

            if ( isPasswordResetForCurrentUser && isPasswordResetByCurrentUser ) {
                this.showConfetti = true;
                break;
                // TODO track that we've shown the user this prompt and
                // don't do it again until they reset their own password again
            }

        }

		// If the current user reset their own password, then
		// show confetti, else continue login flow.
		return ( ( !this.showConfetti ) ? finishLoginFlow() : null );
    }

    public PageReference finishLoginFlow() {
        // Finish the login flow and redirect current user to the default homepage.
        return Auth.SessionManagement.finishLoginFlow();
    }

}