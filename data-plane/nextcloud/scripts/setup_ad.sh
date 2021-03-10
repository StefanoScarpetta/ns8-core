#!/bin/bash

#
# Configure Nextcloud to access Active Directory LDAP
# The script assums that Active Directory already has a user named 'ldapservice' with password set to 'Nethesis,1234'
#

function OCC {
    podman exec -ti --user www-data nextcloud-app php occ "$@"
}

function GET {
    podman run -i --network host --rm docker.io/redis:6-alpine redis-cli HGET nsdc0/module.env $@
}

OCC app:enable user_ldap

# create config if not exists
OCC ldap:show-config s01 &>/dev/null
if [ $? -gt 0 ]; then
    OCC ldap:create-empty-config
fi

HOST=ldaps://$(GET IPADDRESS)
PORT=636
REALM=$(GET REALM)
DN="dc="$(echo $REALM | tr '[:upper:]' '[:lower:]' | sed  's/\./,dc=/g')
BASE_DN=$DN
USER_DN=$DN
GROUP_DN=$DN

BIND_USER=ldapservice@$REALM
BIND_PASSWORD=Nethesis,1234

OCC ldap:set-config s01 ldapHost $HOST
OCC ldap:set-config s01 ldapPort $PORT
OCC ldap:set-config s01 ldapAgentName $BIND_USER
OCC ldap:set-config s01 ldapAgentPassword -- $BIND_PASSWORD
OCC ldap:set-config s01 ldapBase $BASE_DN
OCC ldap:set-config s01 ldapBaseGroups $GROUP_DN
OCC ldap:set-config s01 ldapBaseUsers $USER_DN

OCC ldap:set-config s01 ldapGroupDisplayName cn
OCC ldap:set-config s01 ldapGroupFilter '(&(objectClass=group)(!(cn=backup operators))(!(cn=users))(!(cn=read-only domain controllers))(!(cn=network configuration operators))(!(cn=enterprise admins))(!(cn=domain users))(!(cn=allowed rodc password replication group))(!(cn=iis_iusrs))(!(cn=incoming forest trust builders))(!(cn=domain computers))(!(cn=enterprise read-only domain controllers))(!(cn=replicator))(!(cn=schema admins))(!(cn=group policy creator owners))(!(cn=domain controllers))(!(cn=ras and ias servers))(!(cn=denied rodc password replication group))(!(cn=dnsupdateproxy))(!(cn=print operators))(!(cn=performance log users))(!(cn=account operators))(!(cn=windows authorization access group))(!(cn=server operators))(!(cn=terminal server license servers))(!(cn=remote desktop users))(!(cn=guests))(!(cn=performance monitor users))(!(cn=cert publishers))(!(cn=dnsadmins))(!(cn=cryptographic operators))(!(cn=administrators))(!(cn=event log readers))(!(cn=certificate service dcom access))(!(cn=pre-windows 2000 compatible access))(!(cn=domain guests))(!(cn=distributed com users)))'
OCC ldap:set-config s01 ldapGroupFilterObjectclass group
OCC ldap:set-config s01 ldapGroupMemberAssocAttr member
OCC ldap:set-config s01 ldapLoginFilter '(&(&(|(objectclass=person)))(|(sAMAccountName=%uid)(userPrincipalName=%uid)))'
OCC ldap:set-config s01 ldapLoginFilterMode 0
OCC ldap:set-config s01 ldapLoginFilterUsername 1
OCC ldap:set-config s01 ldapUserDisplayName displayName
OCC ldap:set-config s01 ldapUserDisplayName2 sAMAccountName
OCC ldap:set-config s01 ldapUserFilter '(&(|(objectclass=person)))'
OCC ldap:set-config s01 ldapUserFilterObjectclass person
OCC ldap:set-config s01 ldapEmailAttribute userPrincipalname
OCC ldap:set-config s01 turnOffCertCheck 1
OCC ldap:set-config s01 useMemberOfToDetectMembership 1 # expand all groups
OCC ldap:set-config s01 ldapConfigurationActive 1
OCC ldap:set-config s01 turnOnPasswordChange 1
OCC ldap:set-config s01 ldapTLS 1
