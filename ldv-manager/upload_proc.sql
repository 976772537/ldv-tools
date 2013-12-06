delimiter //

DROP PROCEDURE IF EXISTS upload//
CREATE PROCEDURE upload(
	env VARCHAR(50), username varchar(50), timestamp datetime, driver_spec varchar(255), driver_spec_origin enum('kernel','external'), task_name varchar(255))
BEGIN
  -- environments
  SET @res = 0;
  SELECT id FROM environments WHERE (environments.version = env) LIMIT 1 INTO @res;
  IF @res = 0
    THEN INSERT INTO environments (version) VALUES (env);
    SET @res := LAST_INSERT_ID();
  END IF;
  SET @env_id := @res;
  
  -- tasks
  SET @res = 0;
  SELECT id FROM tasks WHERE (tasks.name = task_name) LIMIT 1 INTO @res;
  IF @res = 0 OR task_name like ''
    THEN INSERT INTO tasks (username, timestamp, driver_spec, driver_spec_origin, name) VALUES (username, timestamp, driver_spec, driver_spec_origin, task_name);
    SET @res := LAST_INSERT_ID();
  END IF;
  SET @task_id := @res;
  
  SELECT @env_id, @task_id;
END//

DROP PROCEDURE IF EXISTS upload_2//
CREATE PROCEDURE upload_2(
	cur_verifier VARCHAR(100), cur_model varchar(20), cur_module varchar(255), driver_origin enum('kernel','external'),
	cur_main varchar(100), environment_id INT, task_id INT)
BEGIN
  -- toolsets
  SET @res = 0;
  SELECT id FROM toolsets WHERE (toolsets.verifier = cur_verifier) LIMIT 1 INTO @res;
  IF @res = 0
    THEN INSERT INTO toolsets (verifier, version) VALUES (cur_verifier, 'current');
    SET @res := LAST_INSERT_ID();
  END IF;
  SET @verifier_id := @res;
  
  -- rule_models
  SET @res = 0;
  SELECT id FROM rule_models WHERE (rule_models.name = cur_model) LIMIT 1 INTO @res;
  IF @res = 0
    THEN INSERT INTO rule_models (name) VALUES (cur_model);
    SET @res := LAST_INSERT_ID();
  END IF;
  SET @model_id := @res;
  
  -- drivers
  SET @res = 0;
  SELECT id FROM drivers WHERE (drivers.name = cur_module and drivers.origin = driver_origin) LIMIT 1 INTO @res;
  IF @res = 0
    THEN INSERT INTO drivers (name, origin) VALUES (cur_module, driver_origin);
    SET @res := LAST_INSERT_ID();
  END IF;
  SET @driver_id := @res;
  
  -- scenarios
  INSERT INTO scenarios (driver_id, executable, main) VALUES (@driver_id, cur_module, cur_main);
  SET @scenario_id := LAST_INSERT_ID();
  
  -- launches
  INSERT INTO launches (driver_id, toolset_id, environment_id, rule_model_id, scenario_id, task_id) VALUES (@driver_id, @verifier_id, environment_id, @model_id, @scenario_id, task_id);
  SET @launch_id := LAST_INSERT_ID();
  
  SELECT @verifier_id, @model_id, @driver_id, @scenario_id, @launch_id;
END//


