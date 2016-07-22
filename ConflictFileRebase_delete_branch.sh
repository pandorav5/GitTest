#/bin/sh

red='\033[0;31m'
NC='\033[0m' # No Color
bold='\033[1m'
green='\033[0;32m'

remote=https://github.com/pandorav5/GitTest3.git
apirepo=https://api.github.com/repos/pandorav5/GitTest3
token='yourtoken'


#first delete GitTest3
#then create remote GitTest3
curl -X DELETE -H "Authorization: token ${token}" $apirepo
curl -i -H "Authorization: token ${token}" \
    -d '{ "name": "GitTest3", "auto_init": false,"private": false}' \
    https://api.github.com/user/repos
	

dev1wd=dev1rebase
dev2wd=dev2rebase
rootwd=c:/GitTest

#this script simulates 2 developers, each has his own branches, working on the same file. it shows with good practices:
#a) each developer in the morning, sync local master with remote master, merge master into his local branch
#b) before pushing, sync local master with remote master, merge his local branch into master, and merge master into his local (a ff merge)
#
#d2 encounters 2 conflicts (in fact, the second conflict happens because d2 forgot the above good pratices)
#d1 doesn't encounter any conflicts
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
echo -e "${green}${bold}rebase t1 onto master${NC}"
git checkout t1
git rebase master
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}merge t1 into master and push to remote master${NC}"
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

echo -e "${green}${bold}delete t1${NC}"
git branch --delete t1
#####################$dev2wd##############################
echo -e "${green}${bold}#####################$dev2wd##############################${NC}"
cd $rootwd/$dev2wd
#!!!!git pull origin master will merge into the current branch, to make sure it merges into the local master branch, first check out master
echo -e "${green}${bold}sync local master with remote master (pull --rebase)${NC}"
git checkout master
git pull --rebase origin master

echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}rebase t2 onto master in $dev2wd, this will run into conflicts 2 times${NC} "	
git checkout t2 
git rebase master

# #!!!! there are 3 commits to be based onto master, t2-c1, t2-c2 you will need to solve conflicts 3 times
# #!!!! if you use merge, you only have to resolve conflict once (because each commit is working on the same file)

# #!!!!! This will fail with the following message:
# # # First, rewinding head to replay your work on top of it...
# # Applying: t2-c1
# # Using index info to reconstruct a base tree...
# # Falling back to patching base and 3-way merge...
# # Auto-merging testf
# # CONFLICT (add/add): Merge conflict in testf
# # Failed to merge in the changes.
# # Patch failed at 0001 t2-c1
# # The copy of the patch that failed is found in:
   # # c:/gittest/berry5/.git/rebase-apply/patch

# # When you have resolved this problem, run "git rebase --continue".
# # If you prefer to skip this patch, run "git rebase --skip" instead.
# # To check out the original branch and stop rebasing, run "git rebase --abort".

ret=$?
if [ $ret != 0 ] 
then
	echo -e "${red}${bold}REBASE ERROR!! I will wait here, please resolve the conflict, come back, and press 1 to continue; press 2 to exit:${NC}"
	select yn in "yes" "no"; do
		case $yn in  
			yes ) break;;	
			no ) exit;;
		esac
	done
fi

#this marks testf conflict is resolved, and rebase can continue 
git add testf
git rebase --continue

#again reapplying t2-c2 fails 
ret=$?
if [ $ret != 0 ] 
then
	echo -e "${red}${bold}REBASE ERROR!! I will wait here, please resolve the conflict, come back, and press 1 to continue; press 2 to exit:${NC}"
	select yn in "yes" "no"; do
		case $yn in  
			yes ) break;;	
			no ) exit;;
		esac
	done
fi
git add testf
git rebase --continue

echo -e "${green}${bold}please check $berrywd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}now i am going to merge t2 into master, this is a fast forward merge${NC}"
git checkout master
git merge t2
git push -v --tags --set-upstream origin master:master
echo -e "${green}${bold}please check $berrywd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}delete t2${NC}"
git branch --delete t2 
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

git checkout -b t3
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}commit t3-c1,t3-c2 into t3${NC}"
echo 't3-c1' >> testf; git add testf; git commit -m 't3-c1'
echo 't3-c2' >> testf1; git add testf1; git commit -m 't3-c2'

echo -e "${green}${bold}merge t3 into master and push to remote master:${NC}"
git checkout master
git merge t3 
git push -v --tags --set-upstream origin master:master

echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}delete t3${NC}"
git branch --delete t3 
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done 
#######################$dev2wd##############################
echo -e "${green}${bold}#######################$dev2wd##############################${NC}"
cd $rootwd/$dev2wd
echo -e "${red}${bold}dev2 made a mistake: he didn't sync his local master with remote, and branch out from a stale master:${NC}"
git checkout master
git checkout -b t4
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}commit t4-c1 into t4${NC}"
echo 't4-c1' >>  testf; git add testf; git commit -m 't4-c1'
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${red}${bold}dev2 realizes his local master is too old${NC}"
echo -e "${green}${bold}sync local master with remote master (pull --rebase)${NC}"
git checkout master
git pull --rebase origin master
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}rebase t4 onto master${NC}"
echo -e "${red}${bold}rebase t4 means recommit t4-c1, dev2 needs to resolve t4-c1 conflict${NC}"
git checkout t4
git rebase master 
ret=$?
if [ $ret != 0 ] 
then
	echo -e "${red}${bold}REBASE ERROR!! I will wait here, please resolve the conflict, come back, and press 1 to continue; press 2 to exit:${NC}"
	select yn in "yes" "no"; do
		case $yn in  
			yes ) break;;	
			no ) exit;;
		esac
	done
fi

git add testf
git rebase --continue
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${red}${bold}at this point, dev2 doesn't want to push his changes to remote master, so he keeps working on t4, commits t4-c2${NC}"
echo 't4-c2' >>  testf; git add testf; git commit -m 't4-c2'
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

echo -e "${green}${bold}branch t5${NC}"
git checkout master
git pull origin master
git checkout -b t5 
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}Commit t5-c1 into t5${NC}"
echo 't5-c1'>> testf; git add testf; git commit -m 't5-c1'
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done


echo -e "${green}${bold} merge t1 into master and push to remote${NC}"
git checkout master 
git pull --rebase origin master
git merge t5
git push -v --tags --set-upstream origin master:master
echo -e "${green}${bold}please check $dev1wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}delete t5${NC}"
git branch --delete t5
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
echo -e "${green}${bold}sync up local master with remote master(pull --rebase) ${NC}"
git checkout master
git pull --rebase origin master
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}rebase t4 onto master ${NC}"
echo -e "${red}${bold}rebase t4 means recommit t4-c1,t4-c2 dev2 needs to resolve t4-c1 conflict again ${NC}"
git checkout t4
git rebase master
ret=$?
if [ $ret != 0 ] 
then
	echo -e "${red}${bold}REBASE ERROR!! I will wait here, please resolve the conflict, come back, and press 1 to continue; press 2 to exit:${NC}"
	select yn in "yes" "no"; do
		case $yn in  
			yes ) break;;	
			no ) exit;;
		esac
	done
fi

git add testf
git rebase --continue 
ret=$?
if [ $ret != 0 ] 
then
	echo -e "${red}${bold}REBASE ERROR!! I will wait here, please resolve the conflict, come back, and press 1 to continue; press 2 to exit:${NC}"
	select yn in "yes" "no"; do
		case $yn in  
			yes ) break;;	
			no ) exit;;
		esac
	done
fi

git add testf
git rebase --continue 
echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${green}${bold}sync up local master with remote master again to simulate resolving conflict takes a long time ${NC}"
git checkout master
git pull --rebase origin master
git merge t4 
git push -v --tags --set-upstream origin master:master

echo -e "${green}${bold}please check $dev2wd, when you are ready, press 1 to continue; press 2 to exit:${NC}"
select yn in "yes" "no"; do
    case $yn in  
        yes ) break;;	
        no ) exit;;
    esac
done

echo -e "${red}${bold}rebase produces a single beautiful line, but it may be more onfusing to developers. In this senario, dev2 has to resolve t4-c1 conflict twice, which is confusing enough; in real life, dev2 commits t4-c1, and commits t4-c2, which adds something and also corrects some mistakes in t4-c1, so it is easier for him to treat t4-c1 and t4-c2 together, and push them together into master; to rebase (recommit t4-c1,t4-c2)is to force him to go through the process of developing t4-c1 and t4-c2 again, which is very counter-intuitive  ${NC}"