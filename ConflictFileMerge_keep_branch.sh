#/bin/sh

red='\033[0;31m'
NC='\033[0m' # No Color
bold='\033[1m'
green='\033[0;32m'

remote=git@github.com:pandorav5/GitTest.git
apirepo=git@api.github.com/repos/pandorav5/GitTest
token='d19d131ac8e06a4dbf3f525bc33a648fd1f3019b'


#first delete GitTest
#then create remote GitTest
curl -X DELETE -H "Authorization: token ${token}" $apirepo
curl -i -H "Authorization: token ${token}" \
    -d '{ "name": "GitTest", "auto_init": false,"private": false}' \
   git@api.github.com/user/repos
	
dev1wd=dev1
dev2wd=dev2
rootwd=c:/git/demo

#this script simulates 2 developers, each has his own branch, working on the same file. 
#a) dev1 is always the lucky one, he gets to push his changes ahead of dev2, so he doesn't run into any conflicts 
#b) dev2 is unlucky, he will run into conflict
#dev1 and dev2 comes from SVN world, and they have the habit of keeping their branches around 
#both devs' practices are:
#before pushing to remote master: 
#1) sync up his local master with remote master 
#2) merge his branch into the local master
#3) push local master to remote 

#for dev2, there is an added scenario:
#dev2 commits some to his local branch, and realizes his local master is behind remote, 
#so he sync up his local master with remote, and merges local master into his branch, continue to work on his branch, and then merges his branch to local master then to remote 
#####################$dev1wd##############################
echo -e "${green}${bold}Create $dev1wd working directory${NC}"
cd $rootwd
rm -rf $dev1wd/*
rm -rf $dev1wd/.[^.]*
git init $dev1wd
cd $dev1wd

#!!!!external diff tools will create .orig files, ignore them
echo \*.orig > .gitignore
echo \*.gitignore >> .gitignore

git config user.name "d1"
git config user.email "d1@sh.com"
#set up credential cache, the first time git push will ask you to input user/pass, it will cache the credential, and won't ask you again
git config credential.helper wincred
#expire in 10 hours 
git config credential.helper 'wincred --timeout=36000'
git remote add origin $remote
git commit --allow-empty -m 'c0'

#set up credential cache, the first time git push will ask you to input user/pass, it will cache the credential, and won't ask you again
git config credential.helper wincred
#expire in 10 hours 
git config credential.helper 'wincred --timeout=36000'

git push -v --tags --set-upstream origin master:master

git checkout -b t1
echo 't1-c1' > testf; git add testf; git commit -m 't1-c1'
echo 't1-c2' >>  testf; git add testf; git commit -m 't1-c2'

echo -e "${green}${bold}please clone $dev1wd into SourceTree and examin it, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

####################$dev2wd##############################
echo -e "${green}${bold}Create $dev2wd working directory${NC}"
cd $rootwd
rm -rf $dev2wd/*
rm -rf $dev2wd/.[^.]*
git init $dev2wd
cd $dev2wd

#!!!!external diff tools will create .orig files, ignore them
echo \*.orig > .gitignore
echo \*.gitignore >> .gitignore

git config user.name "d2"
git config user.email "d2@sh.com"
#set up credential cache, the first time git push will ask you to input user/pass, it will cache the credential, and won't ask you again
git config credential.helper wincred
#expire in 10 hours 
git config credential.helper 'wincred --timeout=36000'
git remote add origin $remote

#!!!!must first use "git fetch origin", otherwise, origin/master, master won't appear in SourceTree
git fetch origin 
git checkout --track -b master origin/master

git checkout -b t2
echo 't2-c1'> testf; git add testf; git commit -m 't2-c1'
echo 't2-c2' >>  testf; git add testf; git commit -m 't2-c2'

echo -e "${green}${bold}please clone $dev2wd into SourceTree and examin it, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

#####################$dev1wd##############################
echo -e "${green}${bold}#####################$dev1wd##############################${NC}"
cd $rootwd/$dev1wd
echo -e "${green}${bold}merge t1 into master and push local master to remote${NC}"
git checkout master
git merge t1
git push -v --tags --set-upstream origin master:master

echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

#####################$dev2wd##############################
echo -e "${green}${bold}#####################$dev2wd##############################${NC}"
cd $rootwd/$dev2wd
#!!!!git pull origin master will merge into the current branch, to make sure it merges into the local master branch, first check out master
echo -e "${green}${bold}sync local master with remote master${NC}"
git checkout master
git pull origin master

echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}merge t2 into master in $dev2wd, this will run into a conflict${NC} "	
git checkout master 
git merge t2
#!!!!this step will fail with:
# Auto-merging testf
# CONFLICT (add/add): Merge conflict in testf
# Automatic merge failed; fix conflicts and then commit the result.

#!!!!notice testf now has content (this also is the content of testf.orig file):
#<<<<<<< HEAD
#t1-c1
#t1-c2
#=======
#t2-c1
#t2-c2
#>>>>>>> t2
#you need to manually change this file to resolve conflict 
ret=$?
if [ $ret != 0 ] 
then
	echo -e "${red}${bold}MERGE ERROR!! I will wait here, please resolve the conflict, come back, and press 1 to continue; press 2 to exit:${NC}"
	select yn in "yes" "no"; do
		case $yn in  
			yes ) break;;	
			no ) exit;;
		esac
	done
fi


git add testf
git commit
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}push local master to remote master${NC}"
git push -v --tags --set-upstream origin master:master

echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}t2 now can be deleted, because it has been merged to master, however dev2 chooses to continue to work on t2, so he merges master into t2${NC}"
git checkout t2 
git merge master 
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done
#####################$dev1wd##############################
echo -e "${green}${bold}#####################$dev1wd##############################${NC}"
cd $rootwd/$dev1wd
#!!!!git pull origin master will merge into the current branch, to make sure it merges into the local master branch, first check out master
echo -e "${green}${bold}sync local master with remote master${NC}"
git checkout master
git pull origin master

echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}checkout t1 and merge master into t1${NC}"
echo -e "${red}${bold}this won't conflict, because t1's contents are already in master${NC}"
git checkout t1
#!!!!here it doesn't conflict!
git merge master
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}commit t1-c3,t1-c4 into t1${NC}"
echo 't1-c3' >> testf; git add testf; git commit -m 't1-c3'
echo 't1-c4' >> testf1; git add testf1; git commit -m 't1-c4'

echo -e "${green}${bold}merge t1 into master and push to remote master:${NC}"
git checkout master
git pull origin master
git merge t1
git push -v --tags --set-upstream origin master:master

echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done
echo -e "${green}${bold}t1 now can be deleted, because it has been merged to master, however dev1 chooses to continue to work on t1, so he merges master into t1${NC}"
git checkout t1
git merge master 
#######################$dev2wd##############################
echo -e "${green}${bold}#######################$dev2wd##############################${NC}"
cd $rootwd/$dev2wd
echo -e "${red}${bold}dev2 didn't realize remote master has changed, and continued to work on his t2:${NC}"
echo -e "${green}${bold}commit t2-c3 into t2${NC}"
git checkout t2
echo 't2-c3' >>  testf; git add testf; git commit -m 't2-c3'
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${red}${bold}dev2 realizes his local master is too old${NC}"
echo -e "${green}${bold}sync local master with remote master${NC}"
git checkout master
git pull origin master
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}merges master into his t2 branch${NC}"
echo -e "${red}${bold}dev2 runs into conflict${NC}"
git checkout t2
git merge master 
ret=$?
if [ $ret != 0 ] 
then
	echo -e "${red}${bold}MERGE ERROR!! I will wait here, please resolve the conflict, come back, and press 1 to continue; press 2 to exit:${NC}"
	select yn in "yes" "no"; do
		case $yn in  
			yes ) break;;	
			no ) exit;;
		esac
	done
fi

git add testf
git commit
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${red}${bold}at this point, dev2 doesn't want to push his changes to remote master, so he keeps working on t2, commits t2-c4${NC}"
echo 't2-c4' >>  testf; git add testf; git commit -m 't2-c4'
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

#####################$dev1wd##############################
echo -e "${green}${bold}#####################$dev1wd##############################${NC}"
cd $rootwd/$dev1wd
#!!!!git pull origin master will merge into the current branch, to make sure it merges into the local master branch, first check out master
echo -e "${green}${bold}Commit t1-c5 into t1${NC}"
echo 't1-c5'>> testf; git add testf; git commit -m 't1-c5'
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}merge t1 into master and push to remote master${NC}"
git checkout master
git pull origin master
git merge t1
git push -v --tags --set-upstream origin master:master
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

######################$dev2wd##############################
echo -e "${green}${bold}######################$dev2wd##############################${NC}"
cd $rootwd/$dev2wd
echo -e "${green}${bold}sync up local master with remote master ${NC}"
git checkout master
git pull origin master
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}merge t2 into master ${NC}"
git merge t2
ret=$?
if [ $ret != 0 ] 
then
	echo -e "${red}${bold}MERGE ERROR!! I will wait here, please resolve the conflict, come back, and press 1 to continue; press 2 to exit:${NC}"
	select yn in "yes" "no"; do
		case $yn in  
			yes ) break;;	
			no ) exit;;
		esac
	done
fi

git add testf
git commit
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}sync up local master with remote master again to simulate resolving conflict takes a long time ${NC}"
git checkout master
git pull origin master
git push -v --tags --set-upstream origin master:master

echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

