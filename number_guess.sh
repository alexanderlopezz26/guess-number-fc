#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo Enter your username:
read USERNAME

USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

if [[ -z $USER_ID ]]
then
  INSERT_NEW_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES ('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
  echo Welcome, $USERNAME! It looks like this is your first time here.
  GAMES_PLAYED=0

else
  USER_RESULTS=$($PSQL "SELECT * FROM users INNER JOIN games USING(user_id) WHERE username='$USERNAME'")
  #separate  user_id | username | games_played | best_game 
  IFS="|" read USER_ID USERNAME GAMES_PLAYED BEST_GAME <<< "$USER_RESULTS"
  echo Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.
fi

FUN_GUESS(){
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
  echo Guess the secret number between 1 and 1000:

  INTENTOS=1
  while true
  do
    read NUMBER

    if [[ $NUMBER =~ ^[0-9]+$ ]]
    then
      if (( $NUMBER < $SECRET_NUMBER ))
      then
        echo -e "It's higher than that, guess again:"
        (( INTENTOS++ ))

      elif (( $NUMBER > $SECRET_NUMBER ))
      then
      echo -e "It's lower than that, guess again:"
      (( INTENTOS++ ))

      elif (( $NUMBER == $SECRET_NUMBER ))
      then
        echo You guessed it in $INTENTOS tries. The secret number was $SECRET_NUMBER. Nice job!
        UPDATE_GAME_INFO
        break
      fi
    else 
      echo That is not an integer, guess again:
    fi
  done
  
}
UPDATE_GAME_INFO(){
  
  if (( GAMES_PLAYED == 0 ))
  then
    INSERT_NEW_GAME_RESULT=$($PSQL "INSERT INTO games (user_id, games_played, best_game) VALUES ($USER_ID, 1, $INTENTOS)")
  
  else
    (( GAMES_PLAYED++ ))

    if (( $INTENTOS < $BEST_GAME ))
    then
      UPDATE_RESULT=$($PSQL "UPDATE games SET games_played=$GAMES_PLAYED, best_game=$INTENTOS WHERE user_id=$USER_ID")
    else
      UPDATE_GAME_RESULT=$($PSQL "UPDATE games SET games_played=$GAMES_PLAYED WHERE user_id=$USER_ID")
    fi
  fi
}

FUN_GUESS